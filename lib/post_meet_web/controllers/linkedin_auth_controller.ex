defmodule PostMeetWeb.LinkedInAuthController do
  use PostMeetWeb, :controller

  alias PostMeet.SocialMedia

  defp linkedin_client_id, do: Application.compile_env(:post_meet, :linkedin_client_id)
  defp linkedin_client_secret, do: Application.compile_env(:post_meet, :linkedin_client_secret)
  defp linkedin_redirect_uri, do: Application.compile_env(:post_meet, :linkedin_redirect_uri)

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

        # Check if user already has LinkedIn account connected
        case SocialMedia.get_account_by_platform(user, "linkedin") do
          nil ->
            # User doesn't have LinkedIn connected, proceed with OAuth
            redirect_to_linkedin_oauth(conn)
          _account ->
            # User already has LinkedIn connected
            conn
            |> put_flash(:info, "LinkedIn account is already connected.")
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
            case get_linkedin_profile(access_token) do
              {:ok, profile} ->
                # Create or update LinkedIn account
                # OpenID Connect response format
                first_name = profile["given_name"] || profile["name"] || "LinkedIn"
                last_name = profile["family_name"] || ""
                full_name = if last_name != "", do: "#{first_name} #{last_name}", else: first_name

                account_params = %{
                  platform: "linkedin",
                  platform_user_id: profile["sub"] || profile["id"],
                  username: full_name,
                  display_name: full_name,
                  access_token: access_token,
                  token_expires_at: DateTime.add(DateTime.utc_now(), expires_in, :second),
                  user_id: user.id
                }

                case SocialMedia.create_account(account_params) do
                  {:ok, _account} ->
                    conn
                    |> put_flash(:info, "LinkedIn account connected successfully!")
                    |> redirect(to: ~p"/social-accounts")

                  {:error, changeset} ->
                    conn
                    |> put_flash(:error, "Failed to connect LinkedIn account: #{inspect(changeset.errors)}")
                    |> redirect(to: ~p"/social-accounts")
                end

              {:error, reason} ->
                conn
                |> put_flash(:error, "Failed to get LinkedIn profile: #{reason}")
                |> redirect(to: ~p"/social-accounts")
            end

          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to get LinkedIn access token: #{reason}")
            |> redirect(to: ~p"/social-accounts")
        end
    end
  end

  def callback(conn, %{"error" => error, "error_description" => description}) do
    conn
    |> put_flash(:error, "LinkedIn authorization failed: #{error} - #{description}")
    |> redirect(to: ~p"/social-accounts")
  end

  defp redirect_to_linkedin_oauth(conn) do
    state = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)

    client_id = linkedin_client_id()
    redirect_uri = linkedin_redirect_uri()

    # Debug logging
    require Logger
    Logger.info("LinkedIn OAuth Debug - Client ID: #{inspect(client_id)}")
    Logger.info("LinkedIn OAuth Debug - Redirect URI: #{inspect(redirect_uri)}")

    params = %{
      response_type: "code",
      client_id: client_id,
      redirect_uri: redirect_uri,
      state: state,
      scope: "openid profile email w_member_social"
    }

    oauth_url = "https://www.linkedin.com/oauth/v2/authorization?" <> URI.encode_query(params)
    Logger.info("LinkedIn OAuth URL: #{oauth_url}")

    redirect(conn, external: oauth_url)
  end

  defp exchange_code_for_token(code) do
    token_url = "https://www.linkedin.com/oauth/v2/accessToken"

    body = %{
      grant_type: "authorization_code",
      code: code,
      redirect_uri: linkedin_redirect_uri(),
      client_id: linkedin_client_id(),
      client_secret: linkedin_client_secret()
    }

    case HTTPoison.post(token_url, {:form, body}, [{"Content-Type", "application/x-www-form-urlencoded"}]) do
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

  defp get_linkedin_profile(access_token) do
    # Use OpenID Connect userinfo endpoint
    profile_url = "https://api.linkedin.com/v2/userinfo"

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.get(profile_url, headers) do
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
