defmodule PostMeetWeb.SocialAccountsController do
  use PostMeetWeb, :controller

  alias PostMeet.SocialMedia

  def index(conn, _params) do
    user = conn.assigns.current_user
    accounts = SocialMedia.list_accounts(user)
    render(conn, :index, accounts: accounts)
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    account = SocialMedia.get_account!(id)

    # Ensure the account belongs to the current user
    if account.user_id == user.id do
      case SocialMedia.delete_account(account) do
        {:ok, _account} ->
          conn
          |> put_flash(:info, "Social media account disconnected successfully.")
          |> redirect(to: ~p"/social-accounts")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Failed to disconnect social media account.")
          |> redirect(to: ~p"/social-accounts")
      end
    else
      conn
      |> put_flash(:error, "Account not found.")
      |> redirect(to: ~p"/social-accounts")
    end
  end

  def toggle(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    account = SocialMedia.get_account!(id)

    # Ensure the account belongs to the current user
    if account.user_id == user.id do
      new_status = !account.is_active

      case SocialMedia.update_account(account, %{is_active: new_status}) do
        {:ok, _account} ->
          status_text = if new_status, do: "activated", else: "deactivated"
          conn
          |> put_flash(:info, "Social media account #{status_text} successfully.")
          |> redirect(to: ~p"/social-accounts")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Failed to update social media account.")
          |> redirect(to: ~p"/social-accounts")
      end
    else
      conn
      |> put_flash(:error, "Account not found.")
      |> redirect(to: ~p"/social-accounts")
    end
  end
end
