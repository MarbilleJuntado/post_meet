defmodule PostMeet.Content.GeneratedContent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "generated_content" do
    field :content_type, :string
    field :platform, :string
    field :content, :string
    field :status, :string, default: "draft"
    field :posted_at, :utc_datetime
    field :social_media_post_id, :string

    belongs_to :meeting, PostMeet.Calendar.Meeting
    belongs_to :automation, PostMeet.Automation.Automation

    timestamps()
  end

  def changeset(content, attrs) do
    content
    |> cast(attrs, [
      :content_type, :platform, :content, :status, :posted_at,
      :social_media_post_id, :meeting_id, :automation_id
    ])
    |> validate_required([:content_type, :platform, :content, :meeting_id, :automation_id])
    |> validate_inclusion(:content_type, ["social_post", "follow_up_email"])
    |> validate_inclusion(:status, ["draft", "posted", "failed"])
    |> foreign_key_constraint(:meeting_id)
    |> foreign_key_constraint(:automation_id)
  end
end




