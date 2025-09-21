defmodule PostMeet.Repo.Migrations.CreateSocialMediaAccounts do
  use Ecto.Migration

  def change do
    create table(:social_media_accounts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :platform, :string, null: false # linkedin, facebook
      add :platform_user_id, :string, null: false
      add :username, :string
      add :display_name, :string
      add :access_token, :text, null: false
      add :refresh_token, :text
      add :token_expires_at, :utc_datetime
      add :is_active, :boolean, default: true

      timestamps()
    end

    create unique_index(:social_media_accounts, [:user_id, :platform, :platform_user_id])
  end
end
