defmodule PostMeet.Accounts do
  @moduledoc """
  The Accounts context for managing users and their Google accounts.
  """

  import Ecto.Query, warn: false
  alias PostMeet.Repo

  alias PostMeet.Accounts.{User, GoogleAccount}

  @doc """
  Gets a user by Google ID.
  """
  def get_user_by_google_id(google_id) do
    Repo.get_by(User, google_id: google_id)
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by ID.
  """
  def get_user_by_id(id) do
    Repo.get(User, id)
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets or creates a user from Google OAuth data.
  """
  def get_or_create_user_from_google(google_data) do
    # First try to find by google_id
    case get_user_by_google_id(google_data["id"]) do
      nil ->
        # If not found by google_id, try by email
        case get_user_by_email(google_data["email"]) do
          nil -> create_user_from_google(google_data)
          existing_user ->
            # Just return the existing user
            {:ok, existing_user}
        end
      user -> {:ok, user}
    end
  end

  defp create_user_from_google(google_data) do
    attrs = %{
      google_id: google_data["id"],
      email: google_data["email"],
      name: google_data["name"],
      avatar_url: google_data["picture"]
    }

    create_user(attrs)
  end

  @doc """
  Lists all Google accounts for a user.
  """
  def list_google_accounts(%User{} = user) do
    Repo.all(from ga in GoogleAccount, where: ga.user_id == ^user.id and ga.is_active == true)
  end

  @doc """
  Gets a Google account by ID.
  """
  def get_google_account!(id), do: Repo.get!(GoogleAccount, id)

  @doc """
  Creates a Google account.
  """
  def create_google_account(attrs \\ %{}) do
    %GoogleAccount{}
    |> GoogleAccount.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a Google account.
  """
  def update_google_account(%GoogleAccount{} = account, attrs) do
    account
    |> GoogleAccount.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Google account.
  """
  def delete_google_account(%GoogleAccount{} = account) do
    Repo.delete(account)
  end
end
