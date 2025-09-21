defmodule PostMeet.Accounts.GoogleAccount do
  use Ecto.Schema
  import Ecto.Changeset

  schema "google_accounts" do
    field :google_id, :string
    field :email, :string
    field :name, :string
    field :access_token, :string
    field :refresh_token, :string
    field :token_expires_at, :utc_datetime
    field :is_active, :boolean, default: true

    belongs_to :user, PostMeet.Accounts.User
    has_many :meetings, PostMeet.Calendar.Meeting

    timestamps()
  end

  def changeset(google_account, attrs) do
    google_account
    |> cast(attrs, [:google_id, :email, :name, :access_token, :refresh_token, :token_expires_at, :is_active, :user_id])
    |> validate_required([:google_id, :email, :name, :access_token, :user_id])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> unique_constraint([:user_id, :google_id])
    |> unique_constraint(:email)
    |> foreign_key_constraint(:user_id)
  end
end




