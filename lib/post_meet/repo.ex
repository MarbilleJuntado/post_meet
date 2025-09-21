defmodule PostMeet.Repo do
  use Ecto.Repo,
    otp_app: :post_meet,
    adapter: Ecto.Adapters.Postgres
end
