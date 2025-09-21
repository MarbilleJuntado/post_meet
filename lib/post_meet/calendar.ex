defmodule PostMeet.Calendar do
  @moduledoc """
  The Calendar context for managing meetings and calendar events.
  """

  import Ecto.Query, warn: false
  alias PostMeet.Repo

  alias PostMeet.Calendar.Meeting

  @doc """
  Lists all meetings for a user.
  """
  def list_meetings(%PostMeet.Accounts.User{} = user) do
    Repo.all(
      from m in Meeting,
        where: m.user_id == ^user.id,
        order_by: [desc: m.start_time],
        preload: [:google_account]
    )
  end

  @doc """
  Lists upcoming meetings for a user.
  """
  def list_upcoming_meetings(%PostMeet.Accounts.User{} = user) do
    now = DateTime.utc_now()

    Repo.all(
      from m in Meeting,
        where: m.user_id == ^user.id and m.start_time > ^now,
        order_by: [asc: m.start_time],
        preload: [:google_account]
    )
  end

  @doc """
  Lists past meetings for a user.
  """
  def list_past_meetings(%PostMeet.Accounts.User{} = user) do
    now = DateTime.utc_now()

    Repo.all(
      from m in Meeting,
        where: m.user_id == ^user.id and m.start_time < ^now,
        order_by: [desc: m.start_time],
        preload: [:google_account]
    )
  end

  @doc """
  Gets a meeting by ID.
  """
  def get_meeting!(id) do
    Repo.get!(Meeting, id)
    |> Repo.preload([:google_account, :generated_content])
  end

  @doc """
  Creates a meeting.
  """
  def create_meeting(attrs \\ %{}) do
    %Meeting{}
    |> Meeting.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a meeting.
  """
  def update_meeting(%Meeting{} = meeting, attrs) do
    meeting
    |> Meeting.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a meeting.
  """
  def delete_meeting(%Meeting{} = meeting) do
    Repo.delete(meeting)
  end

  @doc """
  Updates meeting transcript.
  """
  def update_meeting_transcript(%Meeting{} = meeting, transcript) do
    update_meeting(meeting, %{transcript: transcript, recall_status: "completed"})
  end

  @doc """
  Updates meeting recording URL.
  """
  def update_meeting_recording(%Meeting{} = meeting, recording_url) do
    update_meeting(meeting, %{recording_url: recording_url})
  end

  @doc """
  Toggles notetaker for a meeting.
  """
  def toggle_notetaker(%Meeting{} = meeting) do
    require Logger
    Logger.info("Toggling notetaker for meeting #{meeting.id} from #{meeting.notetaker_enabled} to #{!meeting.notetaker_enabled}")

    result = update_meeting(meeting, %{notetaker_enabled: !meeting.notetaker_enabled})

    case result do
      {:ok, updated_meeting} ->
        Logger.info("Successfully toggled notetaker for meeting #{meeting.id}: #{updated_meeting.notetaker_enabled}")
        {:ok, updated_meeting}
      {:error, changeset} ->
        Logger.error("Failed to toggle notetaker for meeting #{meeting.id}: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  @doc """
  Extracts meeting platform from URL.
  """
  def extract_platform_from_url(url) when is_binary(url) do
    cond do
      String.contains?(url, "zoom.us") -> "zoom"
      String.contains?(url, "teams.microsoft.com") -> "teams"
      String.contains?(url, "meet.google.com") -> "meet"
      true -> "unknown"
    end
  end

  def extract_platform_from_url(_), do: "unknown"

  @doc """
  Syncs calendar events from Google Calendar for a user.
  """
  def sync_calendar_events(%PostMeet.Accounts.User{} = user) do
    # Get all active Google accounts for the user
    google_accounts = PostMeet.Accounts.list_google_accounts(user)

    # Sync events for each Google account
    Enum.each(google_accounts, fn google_account ->
      sync_events_for_account(user, google_account)
    end)
  end

  defp sync_events_for_account(user, google_account) do
    require Logger
    Logger.info("Syncing calendar events for user #{user.id}, google_account #{google_account.id}")

    # Try to fetch events from Google Calendar
    case PostMeet.Calendar.GoogleCalendarService.fetch_calendar_events(google_account.access_token) do
      {:ok, %{"items" => events}} ->
        Logger.info("Fetched #{length(events)} events from Google Calendar")

        # Convert events to meeting format
        meeting_attrs = PostMeet.Calendar.GoogleCalendarService.convert_events_to_meetings(
          events,
          user.id,
          google_account.id
        )

        Logger.info("Converted to #{length(meeting_attrs)} meeting attributes")

        # Create or update meetings
        Enum.each(meeting_attrs, fn attrs ->
          case create_or_update_meeting(attrs) do
            {:ok, _meeting} -> :ok
            {:error, changeset} ->
              require Logger
              Logger.error("Failed to create/update meeting: #{inspect(changeset.errors)}")
          end
        end)

      {:error, "Google Calendar API error: 401"} ->
        # Token expired, try to refresh it
        Logger.info("Access token expired, attempting to refresh...")
        case PostMeet.Calendar.GoogleCalendarService.refresh_access_token(google_account.refresh_token) do
          {:ok, %{"access_token" => new_access_token}} ->
            Logger.info("Token refreshed successfully")

            # Update the Google account with new token
            PostMeet.Accounts.update_google_account(google_account, %{
              access_token: new_access_token,
              token_expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
            })

            # Retry fetching events with new token
            case PostMeet.Calendar.GoogleCalendarService.fetch_calendar_events(new_access_token) do
              {:ok, %{"items" => events}} ->
                Logger.info("Fetched #{length(events)} events after token refresh")

                # Convert and save events
                meeting_attrs = PostMeet.Calendar.GoogleCalendarService.convert_events_to_meetings(
                  events,
                  user.id,
                  google_account.id
                )

                Enum.each(meeting_attrs, fn attrs ->
                  case create_or_update_meeting(attrs) do
                    {:ok, _meeting} -> :ok
                    {:error, changeset} ->
                      Logger.error("Failed to create/update meeting: #{inspect(changeset.errors)}")
                  end
                end)

              {:error, reason} ->
                Logger.error("Failed to fetch events after token refresh: #{inspect(reason)}")
            end

          {:error, reason} ->
            Logger.error("Failed to refresh token: #{inspect(reason)}")
        end

      {:error, reason} ->
        require Logger
        Logger.error("Failed to sync calendar events for user #{user.id}: #{inspect(reason)}")
    end
  end

  defp create_or_update_meeting(attrs) do
    # Check if meeting already exists
    case Repo.get_by(Meeting,
           google_account_id: attrs.google_account_id,
           google_event_id: attrs.google_event_id
         ) do
      nil ->
        # Create new meeting
        case create_meeting(attrs) do
          {:ok, meeting} ->
            require Logger
            Logger.info("Created new meeting: #{meeting.title}")
            {:ok, meeting}
          {:error, changeset} ->
            require Logger
            Logger.error("Failed to create meeting: #{inspect(changeset.errors)}")
            {:error, changeset}
        end

      existing_meeting ->
        # Update existing meeting, but preserve the notetaker_enabled setting
        attrs_with_preserved_notetaker = Map.put(attrs, :notetaker_enabled, existing_meeting.notetaker_enabled)

        case update_meeting(existing_meeting, attrs_with_preserved_notetaker) do
          {:ok, meeting} ->
            require Logger
            Logger.info("Updated existing meeting: #{meeting.title} (preserved notetaker: #{meeting.notetaker_enabled})")
            {:ok, meeting}
          {:error, changeset} ->
            require Logger
            Logger.error("Failed to update meeting: #{inspect(changeset.errors)}")
            {:error, changeset}
        end
    end
  end

  @doc """
  Gets meetings that need notetaker bot.
  """
  def get_meetings_needing_notetaker do
    now = DateTime.utc_now()
    # Get meetings starting in the next 30 minutes that have notetaker enabled
    time_threshold = DateTime.add(now, 30, :minute)

    Repo.all(
      from m in Meeting,
        where: m.notetaker_enabled == true and
               m.start_time > ^now and
               m.start_time <= ^time_threshold and
               (is_nil(m.recall_bot_id) or m.recall_status == "pending"),
        preload: [:google_account, :user]
    )
  end

  @doc """
  Gets meetings with transcripts that are ready for content generation.
  """
  def get_meetings_with_transcripts do
    Repo.all(
      from m in Meeting,
        where: not is_nil(m.transcript),
        where: m.transcript != "",
        order_by: [desc: m.start_time]
    )
  end
end
