defmodule PostMeet.Repo.Migrations.CreateMeetings do
  use Ecto.Migration

  def change do
    create table(:meetings) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :google_account_id, references(:google_accounts, on_delete: :delete_all), null: false
      add :google_event_id, :string, null: false
      add :title, :string, null: false
      add :description, :text
      add :start_time, :utc_datetime, null: false
      add :end_time, :utc_datetime, null: false
      add :attendees, :map, default: %{}
      add :meeting_url, :string
      add :platform, :string # zoom, teams, meet, etc.
      add :recall_bot_id, :string
      add :recall_status, :string, default: "pending" # pending, recording, completed, failed
      add :transcript, :text
      add :recording_url, :string
      add :notetaker_enabled, :boolean, default: false

      timestamps()
    end

    create unique_index(:meetings, [:google_account_id, :google_event_id])
    create index(:meetings, [:user_id, :start_time])
    create index(:meetings, [:recall_bot_id])
  end
end
