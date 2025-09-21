defmodule PostMeetWeb.Auth.Plugs do
  @moduledoc """
  Authentication plugs for the application.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, :fetch_current_user) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: "/auth/google")
        |> halt()
      user_id ->
        case PostMeet.Accounts.get_user_by_id(user_id) do
          nil ->
            conn
            |> put_flash(:error, "User not found. Please log in again.")
            |> redirect(to: "/auth/google")
            |> halt()
          user ->
            assign(conn, :current_user, user)
        end
    end
  end

  def call(conn, :require_user) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access this page.")
      |> redirect(to: "/auth/google")
      |> halt()
    end
  end

  def fetch_current_user(conn, _opts) do
    call(conn, :fetch_current_user)
  end

  def require_user(conn, _opts) do
    call(conn, :require_user)
  end
end
