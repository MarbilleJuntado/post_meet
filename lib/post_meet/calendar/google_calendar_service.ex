defmodule PostMeet.Calendar.GoogleCalendarService do
  @moduledoc """
  Service for interacting with Google Calendar API.
  """

  require Logger

  @google_calendar_api_url "https://www.googleapis.com/calendar/v3"
  @google_oauth_token_url "https://oauth2.googleapis.com/token"
  @client_id "245104452415-h5k68dp9qvudq9jk1216deom3d2b0rn4.apps.googleusercontent.com"
  @client_secret "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"

  @doc """
  Fetches calendar events from Google Calendar API.
  """
  def fetch_calendar_events(access_token, time_min \\ nil, time_max \\ nil) do
    time_min = time_min || DateTime.utc_now() |> DateTime.to_iso8601()
    time_max = time_max || DateTime.add(DateTime.utc_now(), 7, :day) |> DateTime.to_iso8601()

    url = "#{@google_calendar_api_url}/calendars/primary/events"

    params = %{
      "timeMin" => time_min,
      "timeMax" => time_max,
      "singleEvents" => "true",
      "orderBy" => "startTime"
    }

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.get(url, headers, params: params) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, "Failed to parse JSON: #{reason}"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Google Calendar API error: #{status_code} - #{body}")
        {:error, "Google Calendar API error: #{status_code}"}

      {:error, reason} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Converts Google Calendar events to our Meeting schema.
  """
  def convert_events_to_meetings(events, user_id, google_account_id) do
    require Logger
    Logger.info("Converting #{length(events)} events to meetings")

    meetings = events
    |> Enum.map(&convert_event_to_meeting(&1, user_id, google_account_id))
    |> Enum.filter(&(&1 != nil))

    Logger.info("Converted to #{length(meetings)} meetings")
    meetings
  end

  defp convert_event_to_meeting(event, user_id, google_account_id) do
    # Only process events that have a start time and are not all-day events
    case extract_event_times(event) do
      {nil, _} -> nil
      {start_time, end_time} ->
        %{
          user_id: user_id,
          google_account_id: google_account_id,
          google_event_id: event["id"],
          title: event["summary"] || "Untitled Event",
          description: event["description"] || "",
          start_time: start_time,
          end_time: end_time,
          attendees: extract_attendees(event),
          meeting_url: extract_meeting_url(event),
          platform: extract_platform_from_event(event),
          notetaker_enabled: false
        }
    end
  end

  defp extract_event_times(event) do
    start_data = event["start"]
    end_data = event["end"]

    start_time = parse_event_time(start_data)
    end_time = parse_event_time(end_data)

    {start_time, end_time}
  end

  defp parse_event_time(time_data) do
    cond do
      time_data["dateTime"] ->
        case DateTime.from_iso8601(time_data["dateTime"]) do
          {:ok, datetime, _} -> datetime
          _ -> nil
        end

      time_data["date"] ->
        # All-day event, skip for now
        nil

      true ->
        nil
    end
  end

  defp extract_attendees(event) do
    attendees = event["attendees"] || []

    attendees
    |> Enum.map(fn attendee ->
      %{
        "email" => attendee["email"],
        "name" => attendee["displayName"] || attendee["email"],
        "response_status" => attendee["responseStatus"] || "needsAction"
      }
    end)
    |> Enum.with_index()
    |> Enum.into(%{}, fn {attendee, index} -> {to_string(index), attendee} end)
  end

  defp extract_meeting_url(event) do
    # Look for meeting URLs in various fields
    cond do
      event["hangoutLink"] -> event["hangoutLink"]
      event["conferenceData"]["entryPoints"] ->
        entry_points = event["conferenceData"]["entryPoints"]
        case Enum.find(entry_points, &(&1["entryPointType"] == "video")) do
          nil -> nil
          entry_point -> entry_point["uri"]
        end
      true ->
        # Check description for meeting URLs
        description = event["description"] || ""
        extract_url_from_text(description)
    end
  end

  defp extract_url_from_text(text) do
    # Simple regex to find meeting URLs
    zoom_pattern = ~r/https:\/\/[a-zA-Z0-9.-]*zoom\.us\/[a-zA-Z0-9\/?=&-]*/
    teams_pattern = ~r/https:\/\/teams\.microsoft\.com\/[a-zA-Z0-9\/?=&-]*/
    meet_pattern = ~r/https:\/\/meet\.google\.com\/[a-zA-Z0-9\/?=&-]*/

    cond do
      Regex.match?(zoom_pattern, text) ->
        Regex.run(zoom_pattern, text) |> List.first()

      Regex.match?(teams_pattern, text) ->
        Regex.run(teams_pattern, text) |> List.first()

      Regex.match?(meet_pattern, text) ->
        Regex.run(meet_pattern, text) |> List.first()

      true ->
        nil
    end
  end

  defp extract_platform_from_event(event) do
    meeting_url = extract_meeting_url(event)
    PostMeet.Calendar.extract_platform_from_url(meeting_url)
  end

  @doc """
  Exchanges authorization code for access token.
  """
  def exchange_code_for_token(code) do
    url = "https://oauth2.googleapis.com/token"

    body = %{
      "client_id" => @client_id,
      "client_secret" => @client_secret,
      "code" => code,
      "grant_type" => "authorization_code",
      "redirect_uri" => "http://localhost:4000/auth/google/callback"
    }

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post(url, {:form, body}, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"access_token" => access_token, "refresh_token" => refresh_token}} ->
            {:ok, %{access_token: access_token, refresh_token: refresh_token}}
          {:ok, %{"access_token" => access_token}} ->
            {:ok, %{access_token: access_token, refresh_token: nil}}
          {:error, reason} ->
            {:error, "Failed to parse token response: #{reason}"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Token exchange error: #{status_code} - #{body}")
        {:error, "Token exchange failed: #{status_code}"}

      {:error, reason} ->
        Logger.error("Token exchange HTTP error: #{inspect(reason)}")
        {:error, "Token exchange HTTP error: #{inspect(reason)}"}
    end
  end

  @doc """
  Gets user info from Google API.
  """
  def get_user_info(access_token) do
    url = "https://www.googleapis.com/oauth2/v2/userinfo"
    headers = [{"Authorization", "Bearer #{access_token}"}]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, user_info} -> {:ok, user_info}
          {:error, reason} -> {:error, "Failed to parse user info: #{reason}"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("User info API error: #{status_code} - #{body}")
        {:error, "User info API error: #{status_code}"}

      {:error, reason} ->
        Logger.error("User info HTTP error: #{inspect(reason)}")
        {:error, "User info HTTP error: #{inspect(reason)}"}
    end
  end

  @doc """
  Refreshes an expired access token using the refresh token.
  """
  def refresh_access_token(refresh_token) do
    body = %{
      client_id: @client_id,
      client_secret: @client_secret,
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    }

    case HTTPoison.post(@google_oauth_token_url, Jason.encode!(body), [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        {:ok, Jason.decode!(response_body)}
      {:ok, %HTTPoison.Response{status_code: status, body: response_body}} ->
        Logger.error("Failed to refresh token: Status #{status}, Body: #{response_body}")
        {:error, "Failed to refresh token"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTPoison error refreshing token: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
