defmodule PostMeet.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PostMeetWeb.Telemetry,
      PostMeet.Repo,
      {DNSCluster, query: Application.compile_env(:post_meet, :dns_cluster_query, :ignore)},
      {Phoenix.PubSub, name: PostMeet.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PostMeet.Finch},
      # Start Oban for background jobs
      {Oban, Application.compile_env(:post_meet, Oban)},
      # Start the bot scheduler
      PostMeet.Recall.BotScheduler,
      # Start the transcript processor
      PostMeet.Recall.TranscriptProcessor,
      # Start to serve requests, typically the last entry
      PostMeetWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PostMeet.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PostMeetWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
