defmodule PostMeet.AI.ContentTrigger do
  @moduledoc """
  Triggers content generation when meeting transcripts are ready.
  """

  alias PostMeet.{Calendar, Content}

  @doc """
  Triggers content generation for a meeting when its transcript becomes available.
  """
  def trigger_content_generation(meeting_id) do
    meeting = Calendar.get_meeting!(meeting_id)

    if meeting.transcript && String.length(meeting.transcript) > 50 do
      # Generate content for this meeting
      {:ok, results} = Content.generate_content_for_meeting(meeting)
      log_content_generation(meeting, results)
      {:ok, results}
    else
      {:error, "Meeting transcript not ready or too short"}
    end
  end

  @doc """
  Triggers content generation for all meetings with transcripts that don't have content yet.
  """
  def trigger_bulk_content_generation() do
    # Find meetings with transcripts but no generated content
    meetings_with_transcripts = Calendar.get_meetings_with_transcripts()

    results = for meeting <- meetings_with_transcripts do
      case trigger_content_generation(meeting.id) do
        {:ok, content_results} -> {:ok, meeting.id, content_results}
        {:error, reason} -> {:error, meeting.id, reason}
      end
    end

    successful = Enum.count(results, fn
      {:ok, _meeting_id, _content} -> true
      _ -> false
    end)

    failed = Enum.count(results, fn
      {:error, _meeting_id, _reason} -> true
      _ -> false
    end)

    %{
      total: length(meetings_with_transcripts),
      successful: successful,
      failed: failed,
      results: results
    }
  end

  defp log_content_generation(meeting, results) do
    content_count = length(results)
    platforms = results
    |> Enum.map(fn
      {:ok, content} -> content.platform
      {:error, _reason} -> "failed"
    end)
    |> Enum.uniq()

    require Logger
    Logger.info("""
    === CONTENT GENERATION COMPLETED ===
    Meeting: #{meeting.title}
    Content pieces generated: #{content_count}
    Platforms: #{Enum.join(platforms, ", ")}
    """)
  end
end
