defmodule PostMeet.Recall.RecallService do
  @moduledoc """
  Service for integrating with Recall.ai API for meeting recording and transcription.
  """

  require Logger

  @recall_api_url "https://us-west-2.recall.ai/api/v1"
  @bot_name "PostMeet Notetaker"

  @doc """
  Sends a bot to join a meeting.
  """
  def send_bot_to_meeting(meeting, bot_join_minutes \\ 5) do
    Logger.info("=== SEND BOT TO MEETING DEBUG ===")
    Logger.info("Meeting: #{meeting.title}")
    Logger.info("Start time: #{meeting.start_time}")
    Logger.info("Meeting URL: #{meeting.meeting_url}")
    Logger.info("Bot join minutes: #{bot_join_minutes}")

    # Calculate when the bot should join (X minutes before meeting start)
    join_time = DateTime.add(meeting.start_time, -bot_join_minutes, :minute)
    Logger.info("Join time: #{join_time}")
    Logger.info("Current time: #{DateTime.utc_now()}")
    Logger.info("Join time > current time: #{DateTime.compare(join_time, DateTime.utc_now()) == :gt}")

    # Allow bot to join if meeting is happening now or in the future, and has a meeting URL
    # Check if meeting is within 1 hour of start time (allows for early starts)
    meeting_start = meeting.start_time
    meeting_end = meeting.end_time
    now = DateTime.utc_now()

    # Meeting is valid if it's within 1 hour of start time or currently happening
    is_meeting_active = DateTime.compare(meeting_start, DateTime.add(now, -60, :minute)) == :gt and
                       DateTime.compare(meeting_end, now) == :gt

    if is_meeting_active and meeting.meeting_url do
      Logger.info("Conditions met, creating bot...")
      case create_bot(meeting) do
        {:ok, bot_data} ->
          Logger.info("Successfully created Recall.ai bot for meeting #{meeting.id}")
          {:ok, bot_data}

        {:error, reason} ->
          Logger.error("Failed to create Recall.ai bot for meeting #{meeting.id}: #{inspect(reason)}")
          {:error, reason}
      end
    else
      Logger.error("Conditions not met - meeting active: #{is_meeting_active}, has_url: #{!!meeting.meeting_url}")
      {:error, "Meeting is not active or has no meeting URL"}
    end
  end

  @doc """
  Creates a bot via Recall.ai API.
  """
  def create_bot(meeting) do
    url = "#{@recall_api_url}/bot"

    headers = [
      {"Authorization", "Token #{get_api_key()}"},
      {"Content-Type", "application/json"}
    ]

    body = %{
      "bot_name" => @bot_name,
      "meeting_url" => meeting.meeting_url,
      "meeting_start_time" => DateTime.to_iso8601(meeting.start_time),
      "meeting_end_time" => DateTime.to_iso8601(meeting.end_time),
      "recording_config" => %{
        "transcript" => %{
          "provider" => %{
            "recallai_streaming" => %{}
          }
        }
      }
    }

    case HTTPoison.post(url, Jason.encode!(body), headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, bot_data} -> {:ok, bot_data}
          {:error, reason} -> {:error, "Failed to parse bot response: #{reason}"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Recall.ai API error: #{status_code} - #{body}")
        {:error, "Recall.ai API error: #{status_code}"}

      {:error, reason} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Gets bot status from Recall.ai.
  """
  def get_bot_status(bot_id) do
    url = "#{@recall_api_url}/bot/#{bot_id}"

    headers = [
      {"Authorization", "Token #{get_api_key()}"}
    ]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, bot_data} -> {:ok, bot_data}
          {:error, reason} -> {:error, "Failed to parse bot status: #{reason}"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Recall.ai bot status error: #{status_code} - #{body}")
        {:error, "Recall.ai bot status error: #{status_code}"}

      {:error, reason} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Gets bot recording data.
  """
  def get_bot_recording(bot_id) do
    url = "#{@recall_api_url}/bot/#{bot_id}/recording"

    headers = [
      {"Authorization", "Token #{get_api_key()}"}
    ]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, recording_data} -> {:ok, recording_data}
          {:error, reason} -> {:error, "Failed to parse recording data: #{reason}"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Recall.ai recording error: #{status_code} - #{body}")
        {:error, "Recall.ai recording error: #{status_code}"}

      {:error, reason} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Gets bot transcript using the new endpoint format.
  """
  def get_bot_transcript(bot_id) do
    # Use the new transcript endpoint format
    url = "#{@recall_api_url}/transcript/"

    headers = [
      {"Authorization", "Token #{get_api_key()}"}
    ]

    # Get all transcripts and find the one for this bot
    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"results" => transcripts}} ->
            # Find transcript for this bot
            bot_transcript = Enum.find(transcripts, fn transcript ->
              transcript["bot_id"] == bot_id
            end)

            if bot_transcript do
              {:ok, bot_transcript}
            else
              {:error, "No transcript found for bot #{bot_id}"}
            end
          {:ok, response} ->
            {:error, "Unexpected response format: #{inspect(response)}"}
          {:error, reason} ->
            {:error, "Failed to parse transcript list: #{reason}"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Recall.ai transcript error: #{status_code} - #{body}")
        {:error, "Recall.ai transcript error: #{status_code}"}

      {:error, reason} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Processes webhook data from Recall.ai.
  """
  def process_webhook(webhook_data) do
    case webhook_data do
      %{"event" => "bot.recording_ready", "bot" => bot_data} ->
        handle_recording_ready(bot_data)

      %{"event" => "bot.transcript_ready", "bot" => bot_data} ->
        handle_transcript_ready(bot_data)

      %{"event" => "transcript.done", "bot" => bot_data} ->
        handle_transcript_ready(bot_data)

      %{"event" => "bot.status_changed", "bot" => bot_data} ->
        handle_status_changed(bot_data)

      _ ->
        Logger.info("Unknown webhook event: #{inspect(webhook_data)}")
        :ok
    end
  end

  defp handle_recording_ready(bot_data) do
    bot_id = bot_data["id"]

    # Get the meeting associated with this bot
    case get_meeting_by_bot_id(bot_id) do
      nil ->
        Logger.warning("No meeting found for bot #{bot_id}")
        :ok

      meeting ->
        # Update meeting with recording URL
        case get_bot_recording(bot_id) do
          {:ok, recording_data} ->
            recording_url = recording_data["recording_url"]
            PostMeet.Calendar.update_meeting_recording(meeting, recording_url)
            Logger.info("Updated meeting #{meeting.id} with recording URL")

          {:error, reason} ->
            Logger.error("Failed to get recording for bot #{bot_id}: #{inspect(reason)}")
        end
    end
  end

  defp handle_transcript_ready(bot_data) do
    bot_id = bot_data["id"]

    # Get the meeting associated with this bot
    case get_meeting_by_bot_id(bot_id) do
      nil ->
        Logger.warning("No meeting found for bot #{bot_id}")
        :ok

      meeting ->
        # Update meeting with transcript
        case get_bot_transcript(bot_id) do
          {:ok, transcript_data} ->
            transcript = format_transcript(transcript_data)
            PostMeet.Calendar.update_meeting_transcript(meeting, transcript)
            Logger.info("Updated meeting #{meeting.id} with transcript")

          {:error, reason} ->
            Logger.error("Failed to get transcript for bot #{bot_id}: #{inspect(reason)}")
        end
    end
  end

  defp handle_status_changed(bot_data) do
    bot_id = bot_data["id"]
    status = bot_data["status"]

    # Get the meeting associated with this bot
    case get_meeting_by_bot_id(bot_id) do
      nil ->
        Logger.warning("No meeting found for bot #{bot_id}")
        :ok

      meeting ->
        # Update meeting status
        PostMeet.Calendar.update_meeting(meeting, %{recall_status: status})
        Logger.info("Updated meeting #{meeting.id} status to #{status}")
    end
  end

  defp get_meeting_by_bot_id(bot_id) do
    alias PostMeet.Repo
    alias PostMeet.Calendar.Meeting

    Repo.get_by(Meeting, recall_bot_id: bot_id)
  end

  defp format_transcript(transcript_data) do
    # Format the transcript data into a readable string
    # The transcript data comes from the new API format with download_url
    case transcript_data do
      %{"data" => %{"download_url" => download_url}} ->
        # Download the transcript content
        case HTTPoison.get(download_url) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            # Parse the JSON transcript and extract text
            case Jason.decode(body) do
              {:ok, transcript_json} when is_list(transcript_json) ->
                # Extract text from the first participant's words
                if length(transcript_json) > 0 do
                  first_participant = List.first(transcript_json)
                  words = first_participant["words"] || []

                  words
                  |> Enum.map(fn word -> word["text"] end)
                  |> Enum.join(" ")
                else
                  "No transcript content available"
                end
              {:ok, _} ->
                "Unexpected transcript format"
              {:error, reason} ->
                Logger.error("Failed to parse transcript JSON: #{reason}")
                "Failed to parse transcript"
            end
          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
            Logger.error("Failed to download transcript: #{status_code} - #{body}")
            "Failed to download transcript"
          {:error, reason} ->
            Logger.error("Failed to download transcript: #{inspect(reason)}")
            "Failed to download transcript"
        end

      _ ->
        "Transcript not available"
    end
  end

  @doc """
  Manually processes transcript for a specific meeting.
  """
  def process_meeting_transcript(meeting_id) do
    alias PostMeet.Calendar

    try do
      meeting = Calendar.get_meeting!(meeting_id)

      if meeting.recall_bot_id do
        Logger.info("Processing transcript for meeting #{meeting.id}: #{meeting.title}")

        case get_bot_transcript(meeting.recall_bot_id) do
          {:ok, transcript_data} ->
            transcript = format_transcript(transcript_data)
            case Calendar.update_meeting_transcript(meeting, transcript) do
              {:ok, updated_meeting} ->
                Logger.info("✅ Successfully updated meeting #{meeting.id} with transcript")
                {:ok, updated_meeting}
              {:error, reason} ->
                Logger.error("❌ Failed to update meeting #{meeting.id}: #{inspect(reason)}")
                {:error, reason}
            end
          {:error, reason} ->
            Logger.error("❌ Failed to get transcript for meeting #{meeting.id}: #{reason}")
            {:error, reason}
        end
      else
        Logger.error("Meeting #{meeting_id} has no bot ID")
        {:error, "No bot ID"}
      end
    rescue
      Ecto.NoResultsError ->
        Logger.error("Meeting #{meeting_id} not found")
        {:error, "Meeting not found"}
    end
  end

  @doc """
  Manually processes transcripts for all meetings with completed bots.
  This can be called to catch up on any missed webhook events.
  """
  def process_pending_transcripts do
    alias PostMeet.Repo
    alias PostMeet.Calendar.Meeting

    # Get all meetings with completed bots that don't have transcripts yet
    import Ecto.Query
    meetings = Repo.all(
      from m in Meeting,
        where: not is_nil(m.recall_bot_id),
        where: m.recall_status == "completed",
        where: is_nil(m.transcript) or m.transcript == ""
    )

    Logger.info("Found #{length(meetings)} meetings with completed bots but no transcripts")

    Enum.each(meetings, fn meeting ->
      Logger.info("Processing transcript for meeting #{meeting.id}: #{meeting.title}")

      case get_bot_transcript(meeting.recall_bot_id) do
        {:ok, transcript_data} ->
          transcript = format_transcript(transcript_data)
          case PostMeet.Calendar.update_meeting_transcript(meeting, transcript) do
            {:ok, _updated_meeting} ->
              Logger.info("✅ Successfully updated meeting #{meeting.id} with transcript")
            {:error, reason} ->
              Logger.error("❌ Failed to update meeting #{meeting.id}: #{inspect(reason)}")
          end
        {:error, reason} ->
          Logger.error("❌ Failed to get transcript for meeting #{meeting.id}: #{reason}")
      end
    end)
  end

  defp get_api_key do
    System.get_env("RECALL_AI_API_KEY") ||
      Application.compile_env(:post_meet, :recall_ai_api_key) ||
      raise "RECALL_AI_API_KEY environment variable not set"
  end
end
