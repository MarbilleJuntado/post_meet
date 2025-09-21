defmodule PostMeet.Recall.TranscriptProcessor do
  @moduledoc """
  Periodic worker that checks for completed transcripts and updates meetings.
  This is a more reliable alternative to webhooks for development.
  """

  use GenServer
  require Logger

  alias PostMeet.Recall.RecallService

  @check_interval 30_000 # Check every 30 seconds

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_state) do
    # Start the periodic check
    schedule_check()
    Logger.info("TranscriptProcessor started - checking for completed transcripts every 30 seconds")
    {:ok, %{}}
  end

  def handle_info(:check_transcripts, state) do
    check_and_process_transcripts()
    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_transcripts, @check_interval)
  end

  defp check_and_process_transcripts do
    # Get all meetings with completed bots that don't have transcripts yet
    meetings = get_meetings_needing_transcripts()

    if length(meetings) > 0 do
      Logger.info("Found #{length(meetings)} meetings needing transcript processing")

      Enum.each(meetings, fn meeting ->
        Logger.info("Processing transcript for meeting #{meeting.id}: #{meeting.title}")

        case RecallService.process_meeting_transcript(meeting.id) do
          {:ok, updated_meeting} ->
            Logger.info("✅ Successfully processed transcript for meeting #{meeting.id}")
            Logger.info("Transcript length: #{String.length(updated_meeting.transcript)} characters")

            # Trigger AI content generation if automations exist
            trigger_content_generation(updated_meeting)

          {:error, reason} ->
            Logger.warning("❌ Failed to process transcript for meeting #{meeting.id}: #{reason}")
        end
      end)
    else
      Logger.debug("No meetings need transcript processing")
    end
  end

  defp get_meetings_needing_transcripts do
    alias PostMeet.Repo
    alias PostMeet.Calendar.Meeting
    import Ecto.Query

    # Get meetings with completed bots that don't have transcripts yet
    Repo.all(
      from m in Meeting,
        where: not is_nil(m.recall_bot_id),
        where: m.recall_status == "completed",
        where: is_nil(m.transcript) or m.transcript == ""
    )
  end

  defp trigger_content_generation(meeting) do
    # Check if there are any active automations for this user
    user = PostMeet.Accounts.get_user_by_id(meeting.user_id)
    automations = PostMeet.Automation.list_automations(user)

    if length(automations) > 0 do
      Logger.info("Triggering AI content generation for meeting #{meeting.id}")

      case PostMeet.Content.generate_content_for_meeting(meeting) do
        {:ok, results} ->
          Logger.info("✅ Generated #{length(results)} content items for meeting #{meeting.id}")
        error ->
          Logger.error("❌ Failed to generate content for meeting #{meeting.id}: #{inspect(error)}")
      end
    else
      Logger.info("No automations configured for user #{meeting.user_id}, skipping content generation")
    end
  end

  @doc """
  Manually trigger transcript processing for all pending meetings.
  """
  def process_all_pending do
    Logger.info("Manually triggering transcript processing for all pending meetings")
    check_and_process_transcripts()
  end

  @doc """
  Get status of the transcript processor.
  """
  def status do
    meetings = get_meetings_needing_transcripts()
    %{
      pending_meetings: length(meetings),
      meetings: meetings
    }
  end
end
