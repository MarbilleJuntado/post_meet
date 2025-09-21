defmodule PostMeetWeb.FacebookAuthController do
  use PostMeetWeb, :controller

  alias PostMeet.SocialMedia

  @facebook_app_id Application.get_env(:post_meet, :facebook_app_id, nil)
  @facebook_app_secret Application.get_env(:post_meet, :facebook_app_secret, nil)
  @facebook_redirect_uri Application.get_env(:post_meet, :facebook_redirect_uri, "http://localhost:4000/auth/facebook/callback")

  def authorize(conn, _params) do
    # Check if user is authenticated
    case get_session(conn, :user_id) do
      nil ->
        # User is not logged in, redirect to login
        conn
        |> put_flash(:error, "Please log in first to connect your social media accounts.")
        |> redirect(to: ~p"/auth/google")

      user_id ->
        user = PostMeet.Accounts.get_user_by_id(user_id)

        # Check if user already has Facebook account connected
        case SocialMedia.get_account_by_platform(user, "facebook") do
          nil ->
            # User doesn't have Facebook connected, proceed with OAuth
            redirect_to_facebook_oauth(conn)
          _account ->
            # User already has Facebook connected
            conn
            |> put_flash(:info, "Facebook account is already connected.")
            |> redirect(to: ~p"/social-accounts")
        end
    end
  end

  def callback(conn, %{"code" => code, "state" => _state}) do
    # Check if user is authenticated
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "Please log in first to connect your social media accounts.")
        |> redirect(to: ~p"/auth/google")

      user_id ->
        user = PostMeet.Accounts.get_user_by_id(user_id)

        case exchange_code_for_token(code) do
          {:ok, %{access_token: access_token, expires_in: expires_in}} ->
            case get_facebook_profile(access_token) do
              {:ok, profile} ->
                # Create or update Facebook account
                account_params = %{
                  platform: "facebook",
                  platform_user_id: profile["id"],
                  username: profile["name"],
                  display_name: profile["name"],
                  access_token: access_token,
                  token_expires_at: DateTime.add(DateTime.utc_now(), expires_in, :second),
                  user_id: user.id
                }

                case SocialMedia.create_account(account_params) do
                  {:ok, _account} ->
                    conn
                    |> put_flash(:info, "Facebook account connected successfully!")
                    |> redirect(to: ~p"/social-accounts")

                  {:error, changeset} ->
                    conn
                    |> put_flash(:error, "Failed to connect Facebook account: #{inspect(changeset.errors)}")
                    |> redirect(to: ~p"/social-accounts")
                end

              {:error, reason} ->
                conn
                |> put_flash(:error, "Failed to get Facebook profile: #{reason}")
                |> redirect(to: ~p"/social-accounts")
            end

          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to get Facebook access token: #{reason}")
            |> redirect(to: ~p"/social-accounts")
        end
    end
  end

  def callback(conn, %{"error" => error, "error_description" => description}) do
    conn
    |> put_flash(:error, "Facebook authorization failed: #{error} - #{description}")
    |> redirect(to: ~p"/social-accounts")
  end

  defp redirect_to_facebook_oauth(conn) do
    state = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)

    params = %{
      client_id: @facebook_app_id,
      redirect_uri: @facebook_redirect_uri,
      state: state,
      scope: "email,public_profile,pages_manage_posts,pages_read_engagement",
      response_type: "code"
    }

    oauth_url = "https://www.facebook.com/v18.0/dialog/oauth?" <> URI.encode_query(params)

    redirect(conn, external: oauth_url)
  end

  defp exchange_code_for_token(code) do
    token_url = "https://graph.facebook.com/v18.0/oauth/access_token"

    params = %{
      client_id: @facebook_app_id,
      client_secret: @facebook_app_secret,
      redirect_uri: @facebook_redirect_uri,
      code: code
    }

    case HTTPoison.get(token_url <> "?" <> URI.encode_query(params)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"access_token" => access_token, "expires_in" => expires_in}} ->
            {:ok, %{access_token: access_token, expires_in: expires_in}}
          {:error, _} ->
            {:error, "Failed to parse token response"}
        end
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        {:error, "HTTP #{status}: #{body}"}
      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp get_facebook_profile(access_token) do
    profile_url = "https://graph.facebook.com/v18.0/me"

    params = %{
      fields: "id,name,email",
      access_token: access_token
    }

    case HTTPoison.get(profile_url <> "?" <> URI.encode_query(params)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, profile} -> {:ok, profile}
          {:error, _} -> {:error, "Failed to parse profile response"}
        end
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        {:error, "HTTP #{status}: #{body}"}
      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end
end
