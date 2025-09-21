defmodule PostMeetWeb.AutomationController do
  use PostMeetWeb, :controller

  alias PostMeet.Automation

  def index(conn, _params) do
    user = conn.assigns.current_user
    automations = Automation.list_automations(user)
    render(conn, :automation, automations: automations)
  end

  def new(conn, _params) do
    changeset = Automation.change_automation(%Automation.Automation{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"automation" => automation_params}) do
    user = conn.assigns.current_user

    automation_params = Map.put(automation_params, "user_id", user.id)

    case Automation.create_automation(automation_params) do
      {:ok, _automation} ->
        conn
        |> put_flash(:info, "Automation created successfully.")
        |> redirect(to: ~p"/automation")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    automation = Automation.get_automation!(id)
    render(conn, :show, automation: automation)
  end

  def edit(conn, %{"id" => id}) do
    automation = Automation.get_automation!(id)
    changeset = Automation.change_automation(automation)
    render(conn, :edit, automation: automation, changeset: changeset)
  end

  def update(conn, %{"id" => id, "automation" => automation_params}) do
    automation = Automation.get_automation!(id)

    case Automation.update_automation(automation, automation_params) do
      {:ok, _automation} ->
        conn
        |> put_flash(:info, "Automation updated successfully.")
        |> redirect(to: ~p"/automation")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, automation: automation, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    automation = Automation.get_automation!(id)
    {:ok, _automation} = Automation.delete_automation(automation)

    conn
    |> put_flash(:info, "Automation deleted successfully.")
    |> redirect(to: ~p"/automation")
  end

  def toggle(conn, %{"id" => id}) do
    automation = Automation.get_automation!(id)
    new_status = !automation.is_active

    case Automation.update_automation(automation, %{is_active: new_status}) do
      {:ok, _automation} ->
        status_text = if new_status, do: "activated", else: "deactivated"
        conn
        |> put_flash(:info, "Automation #{status_text} successfully.")
        |> redirect(to: ~p"/automation")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to update automation.")
        |> redirect(to: ~p"/automation")
    end
  end
end

