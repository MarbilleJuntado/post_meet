defmodule PostMeet.SocialMedia.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "social_media_accounts" do
    field :platform, :string
    field :platform_user_id, :string
    field :username, :string
    field :display_name, :string
    field :access_token, :string
    field :refresh_token, :string
    field :token_expires_at, :utc_datetime
    field :is_active, :boolean, default: true

    belongs_to :user, PostMeet.Accounts.User

    timestamps()
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :platform, :platform_user_id, :username, :display_name,
      :access_token, :refresh_token, :token_expires_at, :is_active, :user_id
    ])
    |> validate_required([:platform, :platform_user_id, :access_token, :user_id])
    |> validate_inclusion(:platform, ["linkedin", "facebook"])
    |> unique_constraint([:user_id, :platform, :platform_user_id])
    |> foreign_key_constraint(:user_id)
  end
end




