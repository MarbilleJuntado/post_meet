defmodule PostMeet.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string, null: false
      add :google_id, :string, null: false
      add :avatar_url, :string
      add :timezone, :string, default: "UTC"
      add :recall_bot_join_minutes, :integer, default: 5

      timestamps()
    end

    create unique_index(:users, [:google_id])
    create unique_index(:users, [:email])
  end
end
