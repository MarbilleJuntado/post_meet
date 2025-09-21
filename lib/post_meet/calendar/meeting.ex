defmodule PostMeet.Calendar.Meeting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meetings" do
    field :google_event_id, :string
    field :title, :string
    field :description, :string
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :attendees, :map, default: %{}
    field :meeting_url, :string
    field :platform, :string
    field :recall_bot_id, :string
    field :recall_status, :string, default: "pending"
    field :transcript, :string
    field :recording_url, :string
    field :notetaker_enabled, :boolean, default: false

    belongs_to :user, PostMeet.Accounts.User
    belongs_to :google_account, PostMeet.Accounts.GoogleAccount
    has_many :generated_content, PostMeet.Content.GeneratedContent

    timestamps()
  end

  def changeset(meeting, attrs) do
    meeting
    |> cast(attrs, [
      :google_event_id, :title, :description, :start_time, :end_time,
      :attendees, :meeting_url, :platform, :recall_bot_id, :recall_status,
      :transcript, :recording_url, :notetaker_enabled, :user_id, :google_account_id
    ])
    |> validate_required([:google_event_id, :title, :start_time, :end_time, :user_id, :google_account_id])
    |> validate_inclusion(:recall_status, ["pending", "recording", "completed", "failed"])
    |> unique_constraint([:google_account_id, :google_event_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:google_account_id)
  end

  def platform_icon(meeting) do
    case meeting.platform do
      "zoom" -> "🔗"
      "teams" -> "👥"
      "meet" -> "📹"
      _ -> "📞"
    end
  end

  def platform_logo(meeting) do
    case meeting.platform do
      "zoom" ->
        ~s(<svg class="w-6 h-6" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.568 8.16c-.169 0-.333.034-.49.1-.157.066-.3.16-.43.28-.13.12-.24.26-.33.42-.09.16-.15.33-.18.51-.03.18-.05.36-.05.54v6.14c0 .18.02.36.05.54.03.18.09.35.18.51.09.16.2.3.33.42.13.12.27.21.43.28.16.07.32.1.49.1h.86c.17 0 .33-.03.49-.1.16-.07.3-.16.43-.28.13-.12.24-.26.33-.42.09-.16.15-.33.18-.51.03-.18.05-.36.05-.54v-6.14c0-.18-.02-.36-.05-.54-.03-.18-.09-.35-.18-.51-.09-.16-.2-.3-.33-.42-.13-.12-.27-.21-.43-.28-.16-.07-.32-.1-.49-.1h-.86z"/></svg>)
      "teams" ->
        ~s(<svg class="w-6 h-6" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm-1 17h2v-6h-2v6zm1-8a1 1 0 100-2 1 1 0 000 2z"/></svg>)
      "meet" ->
        ~s(<svg class="w-6 h-6" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.568 8.16c-.169 0-.333.034-.49.1-.157.066-.3.16-.43.28-.13.12-.24.26-.33.42-.09.16-.15.33-.18.51-.03.18-.05.36-.05.54v6.14c0 .18.02.36.05.54.03.18.09.35.18.51.09.16.2.3.33.42.13.12.27.21.43.28.16.07.32.1.49.1h.86c.17 0 .33-.03.49-.1.16-.07.3-.16.43-.28.13-.12.24-.26.33-.42.09-.16.15-.33.18-.51.03-.18.05-.36.05-.54v-6.14c0-.18-.02-.36-.05-.54-.03-.18-.09-.35-.18-.51-.09-.16-.2-.3-.33-.42-.13-.12-.27-.21-.43-.28-.16-.07-.32-.1-.49-.1h-.86z"/></svg>)
      _ ->
        ~s(<svg class="w-6 h-6" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.568 8.16c-.169 0-.333.034-.49.1-.157.066-.3.16-.43.28-.13.12-.24.26-.33.42-.09.16-.15.33-.18.51-.03.18-.05.36-.05.54v6.14c0 .18.02.36.05.54.03.18.09.35.18.51.09.16.2.3.33.42.13.12.27.21.43.28.16.07.32.1.49.1h.86c.17 0 .33-.03.49-.1.16-.07.3-.16.43-.28.13-.12.24-.26.33-.42.09-.16.15-.33.18-.51.03-.18.05-.36.05-.54v-6.14c0-.18-.02-.36-.05-.54-.03-.18-.09-.35-.18-.51-.09-.16-.2-.3-.33-.42-.13-.12-.27-.21-.43-.28-.16-.07-.32-.1-.49-.1h-.86z"/></svg>)
    end
  end

  def format_attendees(meeting) do
    case meeting.attendees do
      %{} = attendees when map_size(attendees) > 0 ->
        attendees
        |> Map.values()
        |> Enum.map(fn attendee -> attendee["email"] || attendee["name"] || "Unknown" end)
        |> Enum.join(", ")
      _ -> "No attendees"
    end
  end

  def format_attendees_detailed(meeting) do
    case meeting.attendees do
      %{} = attendees when map_size(attendees) > 0 ->
        attendees
        |> Map.values()
        |> Enum.map(fn attendee ->
          name = attendee["name"] || attendee["email"] || "Unknown"
          email = attendee["email"]
          status = attendee["response_status"] || "needsAction"

          status_icon = case status do
            "accepted" -> "✅"
            "declined" -> "❌"
            "tentative" -> "❓"
            _ -> "⏳"
          end

          "#{status_icon} #{name}#{if email && email != name, do: " (#{email})", else: ""}"
        end)
        |> Enum.join("\n")
      _ -> "No attendees"
    end
  end
end
