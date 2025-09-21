defmodule PostMeet.SocialMedia do
  @moduledoc """
  The SocialMedia context for managing social media accounts and posting.
  """

  import Ecto.Query, warn: false
  alias PostMeet.Repo

  alias PostMeet.SocialMedia.Account

  @doc """
  Lists all social media accounts for a user.
  """
  def list_accounts(%PostMeet.Accounts.User{} = user) do
    Repo.all(
      from a in Account,
        where: a.user_id == ^user.id and a.is_active == true,
        order_by: [asc: a.platform]
    )
  end

  @doc """
  Gets a social media account by ID.
  """
  def get_account!(id), do: Repo.get!(Account, id)

  @doc """
  Gets a social media account by platform and user.
  """
  def get_account_by_platform(%PostMeet.Accounts.User{} = user, platform) do
    Repo.get_by(Account, user_id: user.id, platform: platform, is_active: true)
  end

  @doc """
  Creates a social media account.
  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a social media account.
  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a social media account.
  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Posts content to a social media platform.
  """
  def post_content(%Account{} = account, content) do
    case account.platform do
      "linkedin" -> post_to_linkedin(account, content)
      "facebook" -> post_to_facebook(account, content)
      _ -> {:error, "Unsupported platform"}
    end
  end

  defp post_to_linkedin(%Account{} = account, content) do
    # Check if token is expired
    if is_token_expired?(account) do
      {:error, "LinkedIn access token has expired. Please reconnect your account."}
    else
      post_url = "https://api.linkedin.com/v2/ugcPosts"

      # LinkedIn UGC Post payload
      payload = %{
        author: "urn:li:person:#{account.platform_user_id}",
        lifecycleState: "PUBLISHED",
        specificContent: %{
          "com.linkedin.ugc.ShareContent" => %{
            shareCommentary: %{
              text: content
            },
            shareMediaCategory: "NONE"
          }
        },
        visibility: %{
          "com.linkedin.ugc.MemberNetworkVisibility" => "PUBLIC"
        }
      }

      headers = [
        {"Authorization", "Bearer #{account.access_token}"},
        {"Content-Type", "application/json"},
        {"X-Restli-Protocol-Version", "2.0.0"}
      ]

      case HTTPoison.post(post_url, Jason.encode!(payload), headers) do
        {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
          case Jason.decode(body) do
            {:ok, %{"id" => post_id}} ->
              {:ok, %{post_id: post_id, url: "https://linkedin.com/feed/update/#{post_id}"}}
            {:error, _} ->
              {:error, "Failed to parse LinkedIn response"}
          end
        {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
          {:error, "LinkedIn API error #{status}: #{body}"}
        {:error, reason} ->
          {:error, "HTTP request failed: #{inspect(reason)}"}
      end
    end
  end

  defp post_to_facebook(%Account{} = account, content) do
    # Check if token is expired
    if is_token_expired?(account) do
      {:error, "Facebook access token has expired. Please reconnect your account."}
    else
      # For Facebook, we need to post to a page, not personal profile
      # This requires additional setup with Facebook Pages API
      post_url = "https://graph.facebook.com/v18.0/#{account.platform_user_id}/feed"

      payload = %{
        message: content,
        access_token: account.access_token
      }

      case HTTPoison.post(post_url, {:form, payload}, [{"Content-Type", "application/x-www-form-urlencoded"}]) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, %{"id" => post_id}} ->
              {:ok, %{post_id: post_id, url: "https://facebook.com/#{post_id}"}}
            {:error, _} ->
              {:error, "Failed to parse Facebook response"}
          end
        {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
          {:error, "Facebook API error #{status}: #{body}"}
        {:error, reason} ->
          {:error, "HTTP request failed: #{inspect(reason)}"}
      end
    end
  end

  defp is_token_expired?(%Account{} = account) do
    case account.token_expires_at do
      nil -> false
      expires_at -> DateTime.compare(DateTime.utc_now(), expires_at) == :gt
    end
  end
end
