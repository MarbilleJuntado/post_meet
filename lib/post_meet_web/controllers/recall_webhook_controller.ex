defmodule PostMeetWeb.RecallWebhookController do
  @moduledoc """
  Controller for handling Recall.ai webhooks.
  """

  use PostMeetWeb, :controller

  def webhook(conn, params) do
    # Verify webhook signature if needed
    # For now, we'll trust the webhook data

    case PostMeet.Recall.RecallService.process_webhook(params) do
      :ok ->
        conn
        |> put_status(:ok)
        |> json(%{status: "success"})

      {:error, reason} ->
        require Logger
        Logger.error("Webhook processing failed: #{inspect(reason)}")

        conn
        |> put_status(:internal_server_error)
        |> json(%{status: "error", message: "Webhook processing failed"})
    end
  end
end
