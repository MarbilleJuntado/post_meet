defmodule PostMeet.Repo.Migrations.CreateGoogleAccounts do
  use Ecto.Migration

  def change do
    create table(:google_accounts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :google_id, :string, null: false
      add :email, :string, null: false
      add :name, :string, null: false
      add :access_token, :text, null: false
      add :refresh_token, :text
      add :token_expires_at, :utc_datetime
      add :is_active, :boolean, default: true

      timestamps()
    end

    create unique_index(:google_accounts, [:user_id, :google_id])
    create unique_index(:google_accounts, [:email])
  end
end
