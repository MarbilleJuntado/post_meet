defmodule PostMeetWeb.ContentController do
  use PostMeetWeb, :controller

  alias PostMeet.{Content, Calendar}

  def index(conn, %{"meeting_id" => meeting_id}) do
    user = conn.assigns.current_user
    meeting = Calendar.get_meeting!(meeting_id)

    # Verify the meeting belongs to the current user
    if meeting.user_id != user.id do
      conn
      |> put_flash(:error, "Meeting not found.")
      |> redirect(to: ~p"/dashboard")
    else
      content = Content.list_content_for_meeting(meeting)
      render(conn, :content, content: content, meeting: meeting)
    end
  end


  def update(conn, %{"meeting_id" => meeting_id, "id" => id, "content_item" => content_params}) do
    user = conn.assigns.current_user
    content = Content.get_content!(id)
    meeting = Calendar.get_meeting!(meeting_id)

    # Verify the meeting belongs to the current user and content belongs to the meeting
    if meeting.user_id != user.id or content.meeting_id != meeting.id do
      conn
      |> put_flash(:error, "Content not found.")
      |> redirect(to: ~p"/dashboard")
    else
      case Content.update_content(content, content_params) do
        {:ok, _updated_content} ->
          conn
          |> put_flash(:info, "Content updated successfully.")
          |> redirect(to: ~p"/meetings/#{meeting_id}")

        {:error, %Ecto.Changeset{}} ->
          conn
          |> put_flash(:error, "Failed to update content.")
          |> redirect(to: ~p"/meetings/#{meeting_id}")
      end
    end
  end

  def delete(conn, %{"meeting_id" => meeting_id, "id" => id}) do
    user = conn.assigns.current_user
    content = Content.get_content!(id)
    meeting = Calendar.get_meeting!(meeting_id)

    # Verify the meeting belongs to the current user and content belongs to the meeting
    if meeting.user_id != user.id or content.meeting_id != meeting.id do
      conn
      |> put_flash(:error, "Content not found.")
      |> redirect(to: ~p"/dashboard")
    else
      {:ok, _content} = Content.delete_content(content)

      conn
      |> put_flash(:info, "Content deleted successfully.")
      |> redirect(to: ~p"/meetings/#{meeting_id}")
    end
  end

  def post_to_social(conn, %{"meeting_id" => meeting_id, "id" => id} = params) do
    user = conn.assigns.current_user
    content = Content.get_content!(id)
    meeting = Calendar.get_meeting!(meeting_id)

    # Get platform from params (default to content's platform if not specified)
    platform = params["platform"] || content.platform

    # Verify the meeting belongs to the current user and content belongs to the meeting
    if meeting.user_id != user.id or content.meeting_id != meeting.id do
      conn
      |> put_flash(:error, "Content not found.")
      |> redirect(to: ~p"/dashboard")
    else
      # Get the social media account for this platform
      case PostMeet.SocialMedia.get_account_by_platform(user, platform) do
        nil ->
          conn
          |> put_flash(:error, "No #{platform} account connected. Please connect your account first.")
          |> redirect(to: ~p"/meetings/#{meeting_id}")

        account ->
          # Post to social media
          case PostMeet.SocialMedia.post_content(account, content.content) do
            {:ok, %{post_id: post_id, url: url}} ->
              case Content.mark_as_posted(content, post_id) do
                {:ok, _content} ->
                  conn
                  |> put_flash(:info, "Content posted successfully to #{content.platform}! View post: #{url}")
                  |> redirect(to: ~p"/meetings/#{meeting_id}")

                {:error, _changeset} ->
                  conn
                  |> put_flash(:error, "Failed to update content status.")
                  |> redirect(to: ~p"/meetings/#{meeting_id}")
              end

            {:error, reason} ->
              conn
              |> put_flash(:error, "Failed to post to #{content.platform}: #{reason}")
              |> redirect(to: ~p"/meetings/#{meeting_id}")
          end
      end
    end
  end
end
