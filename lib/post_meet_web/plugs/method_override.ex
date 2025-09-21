defmodule PostMeetWeb.Plugs.MethodOverride do
  @moduledoc """
  Plug to handle method override via _method parameter.
  This allows HTML forms to submit PUT, PATCH, and DELETE requests.
  """

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.params["_method"] do
      method when method in ["PUT", "PATCH", "DELETE"] ->
        conn
        |> put_method(method)
        |> put_params(conn.params)
      _ ->
        conn
    end
  end

  defp put_method(conn, method) do
    %{conn | method: method}
  end

  defp put_params(conn, params) do
    %{conn | params: params}
  end
end
