defmodule PostMeet.Repo.Migrations.CreateGeneratedContent do
  use Ecto.Migration

  def change do
    create table(:generated_content) do
      add :meeting_id, references(:meetings, on_delete: :delete_all), null: false
      add :automation_id, references(:automations, on_delete: :delete_all), null: false
      add :content_type, :string, null: false # social_post, follow_up_email
      add :platform, :string, null: false # linkedin, facebook, email
      add :content, :text, null: false
      add :status, :string, default: "draft" # draft, posted, failed
      add :posted_at, :utc_datetime
      add :social_media_post_id, :string # ID from the platform after posting

      timestamps()
    end

    create index(:generated_content, [:meeting_id])
    create index(:generated_content, [:automation_id])
    create index(:generated_content, [:status])
  end
end
