defmodule PostMeetWeb.PageController do
  use PostMeetWeb, :controller

  def home(conn, _params) do
    # Check if user is already logged in
    case get_session(conn, :user_id) do
      nil ->
        # User is not logged in, show the landing page
        render(conn, :home, layout: false)
      _user_id ->
        # User is logged in, redirect to dashboard
        conn
        |> redirect(to: "/dashboard")
        |> halt()
    end
  end

  def dashboard(conn, _params) do
    user = conn.assigns.current_user

    # Sync calendar events
    PostMeet.Calendar.sync_calendar_events(user)

    # Get meetings for display
    meetings = PostMeet.Calendar.list_meetings(user)
    upcoming_meetings = PostMeet.Calendar.list_upcoming_meetings(user)
    past_meetings = PostMeet.Calendar.list_past_meetings(user)

    render(conn, :dashboard,
      meetings: meetings,
      upcoming_meetings: upcoming_meetings,
      past_meetings: past_meetings,
      current_user: user
    )
  end

  def meeting(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    meeting = PostMeet.Calendar.get_meeting!(id)

    # Ensure the meeting belongs to the current user
    if meeting.user_id == user.id do
      # Load generated content for this meeting
      generated_content = PostMeet.Content.list_content_for_meeting(meeting)
      render(conn, :meeting, meeting: meeting, generated_content: generated_content)
    else
      conn
      |> put_flash(:error, "Meeting not found")
      |> redirect(to: "/dashboard")
    end
  end

  def toggle_notetaker(conn, %{"id" => id} = params) do
    require Logger
    Logger.info("=== TOGGLE NOTETAKER REQUEST ===")
    Logger.info("Request method: #{conn.method}")
    Logger.info("Request path: #{conn.request_path}")
    Logger.info("Request params: #{inspect(params)}")
    Logger.info("CSRF token: #{inspect(conn.params["_csrf_token"])}")
    Logger.info("Session: #{inspect(conn.private[:plug_session])}")

    user = conn.assigns.current_user
    meeting = PostMeet.Calendar.get_meeting!(id)

    Logger.info("Toggle notetaker request for meeting #{id} by user #{user.id}")
    Logger.info("Current notetaker state: #{meeting.notetaker_enabled}")
    Logger.info("Form params: #{inspect(params)}")

    # Ensure the meeting belongs to the current user
    if meeting.user_id == user.id do
      case PostMeet.Calendar.toggle_notetaker(meeting) do
        {:ok, updated_meeting} ->
          Logger.info("Notetaker toggled for meeting #{id}: #{updated_meeting.notetaker_enabled}")

          # Verify the update by fetching the meeting again
          refreshed_meeting = PostMeet.Calendar.get_meeting!(id)
          Logger.info("Verification - meeting #{id} notetaker state after update: #{refreshed_meeting.notetaker_enabled}")

          conn
          |> put_flash(:info, "Notetaker #{if updated_meeting.notetaker_enabled, do: "enabled", else: "disabled"} for #{updated_meeting.title}")
          |> redirect(to: "/dashboard")

        {:error, changeset} ->
          Logger.error("Failed to toggle notetaker for meeting #{id}: #{inspect(changeset.errors)}")
          conn
          |> put_flash(:error, "Failed to update notetaker setting")
          |> redirect(to: "/dashboard")
      end
    else
      Logger.warning("User #{user.id} tried to toggle notetaker for meeting #{id} (belongs to user #{meeting.user_id})")
      conn
      |> put_flash(:error, "Meeting not found")
      |> redirect(to: "/dashboard")
    end
  end

  def generate_social_post(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    meeting = PostMeet.Calendar.get_meeting!(id)

    # Ensure the meeting belongs to the current user
    if meeting.user_id == user.id do
      # Create a LinkedIn automation if it doesn't exist
      linkedin_automation = case PostMeet.Automation.get_automations_by_platform(user, "linkedin") do
        [] ->
          # Create default LinkedIn automation
          {:ok, automation} = PostMeet.Automation.create_automation(%{
            name: "LinkedIn Post Generator",
            type: "generate_post",
            platform: "linkedin",
            description: "Professional and engaging, focus on key business insights",
            user_id: user.id,
            is_active: true
          })
          automation
        [automation | _] -> automation
      end

      # Generate content
      case PostMeet.Automation.generate_content(linkedin_automation, meeting.transcript) do
        {:ok, content} ->
          # Save the generated content
          case PostMeet.Content.create_content(%{
            meeting_id: meeting.id,
            automation_id: linkedin_automation.id,
            content_type: "social_post",
            platform: "linkedin",
            content: content,
            status: "draft"
          }) do
            {:ok, _saved_content} ->
              conn
              |> put_flash(:info, "Social media post generated successfully!")
              |> redirect(to: "/meetings/#{id}")
            {:error, _changeset} ->
              conn
              |> put_flash(:error, "Failed to save generated content")
              |> redirect(to: "/meetings/#{id}")
          end
        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to generate content: #{reason}")
          |> redirect(to: "/meetings/#{id}")
      end
    else
      conn
      |> put_flash(:error, "Meeting not found")
      |> redirect(to: "/dashboard")
    end
  end

  def generate_follow_up_email(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    meeting = PostMeet.Calendar.get_meeting!(id)

    # Ensure the meeting belongs to the current user
    if meeting.user_id == user.id do
      # Create an email automation if it doesn't exist
      email_automation = case PostMeet.Automation.get_automations_by_platform(user, "email") do
        [] ->
          # Create default email automation
          {:ok, automation} = PostMeet.Automation.create_automation(%{
            name: "Email Follow-up Generator",
            type: "generate_email",
            platform: "email",
            description: "Professional and courteous, include meeting summary and next steps",
            user_id: user.id,
            is_active: true
          })
          automation
        [automation | _] -> automation
      end

      # Generate content
      case PostMeet.Automation.generate_content(email_automation, meeting.transcript) do
        {:ok, content} ->
          # Save the generated content
          case PostMeet.Content.create_content(%{
            meeting_id: meeting.id,
            automation_id: email_automation.id,
            content_type: "follow_up_email",
            platform: "email",
            content: content,
            status: "draft"
          }) do
            {:ok, _saved_content} ->
              conn
              |> put_flash(:info, "Follow-up email generated successfully!")
              |> redirect(to: "/meetings/#{id}")
            {:error, _changeset} ->
              conn
              |> put_flash(:error, "Failed to save generated content")
              |> redirect(to: "/meetings/#{id}")
          end
        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to generate content: #{reason}")
          |> redirect(to: "/meetings/#{id}")
      end
    else
      conn
      |> put_flash(:error, "Meeting not found")
      |> redirect(to: "/dashboard")
    end
  end
end
