defmodule PostMeet.Automation do
  @moduledoc """
  The Automation context for managing content generation automations.
  """

  import Ecto.Query, warn: false
  alias PostMeet.Repo

  alias PostMeet.Automation.Automation

  @doc """
  Lists all automations for a user.
  """
  def list_automations(%PostMeet.Accounts.User{} = user) do
    Repo.all(
      from a in Automation,
        where: a.user_id == ^user.id and a.is_active == true,
        order_by: [asc: a.platform, asc: a.name]
    )
  end

  @doc """
  Gets an automation by ID.
  """
  def get_automation!(id) do
    Repo.get!(Automation, id)
  end

  @doc """
  Gets automations by platform for a user.
  """
  def get_automations_by_platform(%PostMeet.Accounts.User{} = user, platform) do
    Repo.all(
      from a in Automation,
        where: a.user_id == ^user.id and a.platform == ^platform and a.is_active == true,
        order_by: [asc: a.name]
    )
  end

  @doc """
  Creates an automation.
  """
  def create_automation(attrs \\ %{}) do
    %Automation{}
    |> Automation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an automation.
  """
  def update_automation(%Automation{} = automation, attrs) do
    automation
    |> Automation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an automation.
  """
  def delete_automation(%Automation{} = automation) do
    Repo.delete(automation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking automation changes.
  """
  def change_automation(%Automation{} = automation, attrs \\ %{}) do
    Automation.changeset(automation, attrs)
  end

  @doc """
  Generates content using an automation.
  """
  def generate_content(%Automation{} = automation, meeting_transcript) do
    case automation.type do
      "generate_post" -> generate_social_post(automation, meeting_transcript)
      "generate_email" -> generate_follow_up_email(automation, meeting_transcript)
      _ -> {:error, "Unknown automation type"}
    end
  end

  defp generate_social_post(%Automation{} = automation, transcript) do
    # Use AI content generator for social posts
    automation_config = %{
      tone: automation.description,
      max_length: 280
    }

    PostMeet.AI.ContentGenerator.generate_social_post(transcript, automation.platform, automation_config)
  end

  defp generate_follow_up_email(%Automation{} = automation, transcript) do
    # Use AI content generator for emails
    automation_config = %{
      tone: automation.description
    }

    PostMeet.AI.ContentGenerator.generate_follow_up_email(transcript, automation_config)
  end
end
