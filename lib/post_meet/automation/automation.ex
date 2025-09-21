defmodule PostMeet.Automation.Automation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "automations" do
    field :name, :string
    field :type, :string
    field :platform, :string
    field :description, :string
    field :example, :string
    field :is_active, :boolean, default: true

    belongs_to :user, PostMeet.Accounts.User
    has_many :generated_content, PostMeet.Content.GeneratedContent

    timestamps()
  end

  def changeset(automation, attrs) do
    automation
    |> cast(attrs, [:name, :type, :platform, :description, :example, :is_active, :user_id])
    |> validate_required([:name, :type, :platform, :description, :user_id])
    |> validate_inclusion(:type, ["generate_post", "generate_email"])
    |> validate_inclusion(:platform, ["linkedin", "facebook", "email"])
    |> foreign_key_constraint(:user_id)
  end
end




