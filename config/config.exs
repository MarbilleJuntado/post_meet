# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project. If another project (or dependency)
# is using this file as a dependency, the `:import_config` macro
# will not be available, so the `use Mix.Config` line is not needed.
#
# General application configuration
import Config

# Configure Ecto repos
config :post_meet, ecto_repos: [PostMeet.Repo]

# Configures the endpoint
config :post_meet, PostMeetWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PostMeetWeb.ErrorHTML, json: PostMeetWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PostMeet.PubSub,
  live_view: [signing_salt: "your_signing_salt_here"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.19.11",
  post_meet: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  post_meet: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Guardian configuration
config :post_meet, Guardian,
  issuer: "post_meet",
  secret_key: "CCK9aEXKOmS/z42wCl6wUJltWTGNic+5Ug/DYPS+PVg="

# Google OAuth configuration
config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [
      default_scope: "openid email profile https://www.googleapis.com/auth/calendar.readonly",
      request_path: "/auth/google",
      callback_path: "/auth/google/callback"
    ]}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: "245104452415-h5k68dp9qvudq9jk1216deom3d2b0rn4.apps.googleusercontent.com",
  client_secret: "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"

# Configure Oban for background jobs
config :post_meet, Oban,
  repo: PostMeet.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [recall: 10]

# Recall.ai API configuration
config :post_meet, :recall_ai_api_key, System.get_env("RECALL_AI_API_KEY")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
