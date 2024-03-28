defmodule PortfolioWeb.Router do
  use PortfolioWeb, :router
  alias PortfolioWeb.Plugs.SetLocale
  alias PortfolioWeb.Plugs.LocaleRedirection
  alias PortfolioWeb.Plugs.CommonMetadata
  import Phoenix.LiveView.Router

  pipeline :locale do
    plug SetLocale
    plug LocaleRedirection
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PortfolioWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug CommonMetadata
  end

  # TODO: Is a white list the best way to handle avoiding :locale?
  pipeline :admin do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PortfolioWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug CommonMetadata
    # Do not include the LocaleRedirection plug here
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Enables LiveDashboard only for development.
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # Conditional block for development-only routes
  # We're defining these first as to not trigger the :locale redirection pipeline.
  if Mix.env() in [:dev, :test] do
    scope "/admin", PortfolioWeb do
      # Use the :admin pipeline
      pipe_through [:admin]

      # Admin routes for /up and /dashboard
      get "/up/", UpController, :index
      get "/up/databases", UpController, :databases

      # LiveDashboard route
      import Phoenix.LiveDashboard.Router
      live_dashboard "/dashboard", metrics: PortfolioWeb.Telemetry

      # LiveView routes for Case Studies
      live "/case-study", CaseStudyLive.Index, :index
      live "/case-study/new", CaseStudyLive.Index, :new
      live "/case-study/:id/edit", CaseStudyLive.Index, :edit
      live "/case-study/:id", CaseStudyLive.Show, :show
      live "/case-study/:id/show/edit", CaseStudyLive.Show, :edit
    end
  end

  scope "/", PortfolioWeb do
    pipe_through [:browser, :locale]

    get "/", PageController, :root
  end

  scope "/:locale", PortfolioWeb do
    pipe_through [:browser, :locale]

    get "/", PageController, :home
    get "/case-study/:url", CaseStudyController, :show
  end

  # Catch-all route for unmatched paths
  scope "/", PortfolioWeb do
    pipe_through :browser
    get "/up/", UpController, :index
    get "/up/databases", UpController, :databases
  end

  scope "/api", PortfolioWeb do
    post "/session/generate", SessionController, :generate
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:new, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PortfolioWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
