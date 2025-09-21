defmodule PostMeet.Repo.Migrations.CreateAutomations do
  use Ecto.Migration

  def change do
    create table(:automations) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :type, :string, null: false # generate_post, generate_email
      add :platform, :string, null: false # linkedin, facebook, email
      add :description, :text, null: false
      add :example, :text
      add :is_active, :boolean, default: true

      timestamps()
    end

    create index(:automations, [:user_id, :platform])
  end
end
