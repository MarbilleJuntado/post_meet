defmodule PostMeetWeb.UeberauthController do
  use PostMeetWeb, :controller

  def callback(conn, params) do
    case params do
      %{"error" => error} ->
        conn
        |> put_flash(:error, "Authentication failed: #{error}")
        |> redirect(to: "/")

      %{"code" => code} ->
        # Exchange the authorization code for an access token
        case PostMeet.Calendar.GoogleCalendarService.exchange_code_for_token(code) do
          {:ok, %{access_token: access_token, refresh_token: refresh_token}} ->
            # Get user info from Google
            case PostMeet.Calendar.GoogleCalendarService.get_user_info(access_token) do
              {:ok, user_info} ->
                # Create or get user
                case PostMeet.Accounts.get_or_create_user_from_google(user_info) do
                  {:ok, user} ->
                    # Store the Google account with tokens
                    create_google_account(user, user_info, access_token, refresh_token)

                    conn
                    |> put_session(:user_id, user.id)
                    |> put_flash(:info, "Successfully authenticated with Google!")
                    |> redirect(to: "/dashboard")

                  {:error, reason} ->
                    conn
                    |> put_flash(:error, "Failed to create user account: #{inspect(reason)}")
                    |> redirect(to: "/")
                end

              {:error, reason} ->
                conn
                |> put_flash(:error, "Failed to get user info: #{inspect(reason)}")
                |> redirect(to: "/")
            end

          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to exchange code for token: #{inspect(reason)}")
            |> redirect(to: "/")
        end

      _ ->
        conn
        |> put_flash(:error, "Invalid authentication response")
        |> redirect(to: "/")
    end
  end

  defp create_google_account(user, user_info, access_token, refresh_token) do
    # Calculate token expiration (Google tokens typically expire in 1 hour)
    expires_at = DateTime.add(DateTime.utc_now(), 3600, :second)

    PostMeet.Accounts.create_google_account(%{
      user_id: user.id,
      google_id: user_info["id"],
      email: user_info["email"],
      name: user_info["name"],
      access_token: access_token,
      refresh_token: refresh_token,
      token_expires_at: expires_at,
      is_active: true
    })
  end
end
