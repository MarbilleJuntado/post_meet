defmodule PostMeet.Recall.SendBotJob do
  @moduledoc """
  Oban job for sending Recall.ai bots to meetings.
  """

  use Oban.Worker, queue: :recall

  alias PostMeet.Calendar

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"meeting_id" => meeting_id}}) do
    require Logger
    Logger.info("=== SEND BOT JOB DEBUG ===")
    Logger.info("Meeting ID: #{meeting_id}")

    case Calendar.get_meeting!(meeting_id) do
      nil ->
        Logger.error("Meeting not found: #{meeting_id}")
        {:error, "Meeting not found"}

      meeting ->
        Logger.info("Meeting found: #{meeting.title}")
        Logger.info("Notetaker enabled: #{meeting.notetaker_enabled}")
        Logger.info("Meeting URL: #{meeting.meeting_url}")
        Logger.info("Bot ID: #{meeting.recall_bot_id}")

        if meeting.notetaker_enabled and meeting.recall_bot_id == nil do
          Logger.info("Attempting to send bot to meeting...")
          case PostMeet.Recall.RecallService.send_bot_to_meeting(meeting) do
            {:ok, bot_data} ->
              Logger.info("Bot sent successfully: #{inspect(bot_data)}")
              # Update meeting with bot ID atomically to prevent race conditions
              case Calendar.update_meeting(meeting, %{
                recall_bot_id: bot_data["id"],
                recall_status: "pending"
              }) do
                {:ok, _updated_meeting} ->
                  Logger.info("Meeting #{meeting_id} updated with bot ID: #{bot_data["id"]}")
                  {:ok, "Bot sent to meeting #{meeting_id}"}

                {:error, changeset} ->
                  Logger.error("Failed to update meeting with bot ID: #{inspect(changeset.errors)}")
                  {:error, "Failed to update meeting with bot ID"}
              end

            {:error, reason} ->
              Logger.error("Failed to send bot: #{inspect(reason)}")
              {:error, "Failed to send bot: #{inspect(reason)}"}
          end
        else
          Logger.info("Bot not needed - notetaker: #{meeting.notetaker_enabled}, bot_id: #{meeting.recall_bot_id}")
          {:ok, "Bot not needed for meeting #{meeting_id}"}
        end
    end
  end
end
