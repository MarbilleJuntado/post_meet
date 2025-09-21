defmodule PostMeet.Content do
  @moduledoc """
  The Content context for managing generated content.
  """

  import Ecto.Query, warn: false
  alias PostMeet.Repo

  alias PostMeet.Content.GeneratedContent

  @doc """
  Lists all generated content for a meeting.
  """
  def list_content_for_meeting(%PostMeet.Calendar.Meeting{} = meeting) do
    Repo.all(
      from gc in GeneratedContent,
        where: gc.meeting_id == ^meeting.id,
        order_by: [asc: gc.platform, asc: gc.content_type],
        preload: [:automation]
    )
  end

  @doc """
  Lists all generated content for multiple meetings.
  """
  def list_content_for_meetings(meeting_ids) do
    Repo.all(
      from gc in GeneratedContent,
        where: gc.meeting_id in ^meeting_ids,
        order_by: [desc: gc.inserted_at],
        preload: [:meeting, :automation]
    )
  end

  @doc """
  Gets generated content by ID.
  """
  def get_content!(id) do
    Repo.get!(GeneratedContent, id)
    |> Repo.preload([:meeting, :automation])
  end

  @doc """
  Creates generated content.
  """
  def create_content(attrs \\ %{}) do
    %GeneratedContent{}
    |> GeneratedContent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates generated content.
  """
  def update_content(%GeneratedContent{} = content, attrs) do
    content
    |> GeneratedContent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes generated content.
  """
  def delete_content(%GeneratedContent{} = content) do
    Repo.delete(content)
  end

  @doc """
  Marks content as posted.
  """
  def mark_as_posted(%GeneratedContent{} = content, social_media_post_id) do
    update_content(content, %{
      status: "posted",
      posted_at: DateTime.utc_now(),
      social_media_post_id: social_media_post_id
    })
  end

  @doc """
  Marks content as failed.
  """
  def mark_as_failed(%GeneratedContent{} = content) do
    update_content(content, %{status: "failed"})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking content changes.
  """
  def change_content(%GeneratedContent{} = content, attrs \\ %{}) do
    GeneratedContent.changeset(content, attrs)
  end

  @doc """
  Generates content for a meeting using all active automations.
  """
  def generate_content_for_meeting(%PostMeet.Calendar.Meeting{} = meeting) do
    user = PostMeet.Accounts.get_user_by_id(meeting.user_id)
    automations = PostMeet.Automation.list_automations(user)

    results =
      for automation <- automations do
        case PostMeet.Automation.generate_content(automation, meeting.transcript) do
          {:ok, content} ->
            create_content(%{
              meeting_id: meeting.id,
              automation_id: automation.id,
              content_type: get_content_type(automation.type),
              platform: automation.platform,
              content: content,
              status: "draft"
            })
          {:error, reason} ->
            {:error, reason}
        end
      end

    # Filter out any errors and return only successful results
    successful_results = Enum.filter(results, fn
      {:ok, _content} -> true
      {:error, _reason} -> false
    end)

    {:ok, successful_results}
  end

  defp get_content_type("generate_post"), do: "social_post"
  defp get_content_type("generate_email"), do: "follow_up_email"
  defp get_content_type(_), do: "social_post"
end
