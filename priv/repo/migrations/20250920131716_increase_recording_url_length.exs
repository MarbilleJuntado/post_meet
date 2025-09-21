defmodule PostMeet.Repo.Migrations.IncreaseRecordingUrlLength do
  use Ecto.Migration

  def change do
    alter table(:meetings) do
      modify :recording_url, :text
    end
  end
end
