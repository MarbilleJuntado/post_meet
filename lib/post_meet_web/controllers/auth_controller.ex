defmodule PostMeetWeb.AuthController do
  use PostMeetWeb, :controller

  alias PostMeet.Accounts

  @google_client_id Application.get_env(:post_meet, :google_client_id)

  def request(conn, _params) do
    # Redirect to Google OAuth
    client_id = System.get_env("GOOGLE_CLIENT_ID") || @google_client_id
    oauth_url = "https://accounts.google.com/o/oauth2/v2/auth?" <>
      "client_id=#{client_id}&" <>
      "redirect_uri=https://post-meet.fly.dev/auth/google/callback&" <>
      "response_type=code&" <>
      "scope=openid%20email%20profile%20https://www.googleapis.com/auth/calendar.readonly&" <>
      "access_type=offline"

    redirect(conn, external: oauth_url)
  end

  def callback(conn, _params) do
    # Mock authentication for now
    {:ok, user_info} = get_user_info("mock_token")

    case Accounts.get_or_create_user_from_google(user_info) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Successfully authenticated!")
        |> redirect(to: "/dashboard")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to create user account: #{inspect(reason)}")
        |> redirect(to: "/")
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "You have been logged out")
    |> redirect(to: "/")
  end

  defp get_user_info(_token) do
    # TODO: Implement Google API call to get user info
    # For now, return mock data
    {:ok, %{
      "id" => "google_test_user",
      "email" => "webshookeng@gmail.com",
      "name" => "Test User",
      "picture" => "https://via.placeholder.com/150"
    }}
  end
end
