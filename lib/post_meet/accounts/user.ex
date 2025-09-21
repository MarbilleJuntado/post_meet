defmodule PostMeet.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    field :google_id, :string
    field :avatar_url, :string
    field :timezone, :string, default: "UTC"
    field :recall_bot_join_minutes, :integer, default: 5

    has_many :google_accounts, PostMeet.Accounts.GoogleAccount
    has_many :meetings, PostMeet.Calendar.Meeting
    has_many :social_media_accounts, PostMeet.SocialMedia.Account
    has_many :automations, PostMeet.Automation.Automation

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :google_id, :avatar_url, :timezone, :recall_bot_join_minutes])
    |> validate_required([:email, :name, :google_id])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> unique_constraint(:google_id)
    |> unique_constraint(:email)
  end
end




