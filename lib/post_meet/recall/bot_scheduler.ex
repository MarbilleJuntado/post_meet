defmodule PostMeet.Recall.BotScheduler do
  @moduledoc """
  Scheduler for sending Recall.ai bots to meetings.
  """

  use GenServer
  require Logger

  alias PostMeet.Calendar

  @check_interval 60_000 # Check every minute

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_state) do
    # Start the periodic check
    schedule_check()
    {:ok, %{}}
  end

  def handle_info(:check_meetings, state) do
    check_and_schedule_bots()
    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_meetings, @check_interval)
  end

  defp check_and_schedule_bots do
    # Get meetings that need notetaker bots
    meetings = Calendar.get_meetings_needing_notetaker()

    Logger.info("Found #{length(meetings)} meetings needing notetaker bots")

    Enum.each(meetings, fn meeting ->
      # Double-check that this meeting doesn't already have a bot
      # This prevents race conditions
      if is_nil(meeting.recall_bot_id) do
        # Calculate when to send the bot (X minutes before meeting)
        bot_send_time = DateTime.add(meeting.start_time, -meeting.user.recall_bot_join_minutes, :minute)

        # Only schedule if the bot send time is in the future
        if DateTime.compare(bot_send_time, DateTime.utc_now()) == :gt do
          # Schedule the job to run at the calculated time
          PostMeet.Recall.SendBotJob.new(%{"meeting_id" => meeting.id}, schedule_at: bot_send_time)
          |> Oban.insert()

          Logger.info("Scheduled bot for meeting #{meeting.id} at #{bot_send_time}")
        else
          # Send immediately if the time has passed
          PostMeet.Recall.SendBotJob.new(%{"meeting_id" => meeting.id})
          |> Oban.insert()

          Logger.info("Sending bot immediately for meeting #{meeting.id}")
        end
      else
        Logger.info("Meeting #{meeting.id} already has bot #{meeting.recall_bot_id}, skipping")
      end
    end)
  end
end
