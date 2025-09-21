defmodule PostMeetWeb.Router do
  use PostMeetWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PostMeetWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PostMeetWeb.Plugs.MethodOverride
  end

  pipeline :protected do
    plug PostMeetWeb.Auth.Plugs, :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PostMeetWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Webhook routes (no authentication required)
  scope "/webhooks", PostMeetWeb do
    pipe_through :api

    post "/recall", RecallWebhookController, :webhook
  end

  scope "/", PostMeetWeb do
    pipe_through [:browser, :protected]

    get "/dashboard", PageController, :dashboard
    get "/meetings/:id", PageController, :meeting
    patch "/meetings/:id/toggle_notetaker", PageController, :toggle_notetaker
    post "/meetings/:id/generate_social_post", PageController, :generate_social_post
    post "/meetings/:id/generate_follow_up_email", PageController, :generate_follow_up_email

        # Content routes as subroutes of meetings
        get "/meetings/:meeting_id/content", ContentController, :index
        patch "/meetings/:meeting_id/content/:id", ContentController, :update
        delete "/meetings/:meeting_id/content/:id", ContentController, :delete
        post "/meetings/:meeting_id/content/:id/post", ContentController, :post_to_social

    # Automation routes
    get "/automation", AutomationController, :index
    get "/automation/new", AutomationController, :new
    post "/automation", AutomationController, :create
    get "/automation/:id", AutomationController, :show
    get "/automation/:id/edit", AutomationController, :edit
    patch "/automation/:id", AutomationController, :update
    delete "/automation/:id", AutomationController, :delete
    patch "/automation/:id/toggle", AutomationController, :toggle

    # Social media accounts routes
    get "/social-accounts", SocialAccountsController, :index
    delete "/social-accounts/:id", SocialAccountsController, :delete
    patch "/social-accounts/:id/toggle", SocialAccountsController, :toggle
  end

  scope "/auth", PostMeetWeb do
    pipe_through :browser

    get "/google", AuthController, :request
    get "/google/callback", UeberauthController, :callback, provider: :google
    post "/logout", AuthController, :logout
  end

  # Social media OAuth routes (no authentication required for initial connection)
  scope "/auth", PostMeetWeb do
    pipe_through :browser

    get "/linkedin", LinkedInAuthController, :authorize
    get "/linkedin/callback", LinkedInAuthController, :callback
    get "/facebook", FacebookAuthController, :authorize
    get "/facebook/callback", FacebookAuthController, :callback
  end

  # Other scopes may use custom stacks.
  # scope "/api", PostMeetWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:post_meet, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PostMeetWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
