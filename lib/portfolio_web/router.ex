defmodule PortfolioWeb.Router do
  use PortfolioWeb, :router
  alias PortfolioWeb.Plugs.SetLocale
  alias PortfolioWeb.Plugs.LocaleRedirection
  alias PortfolioWeb.Plugs.CommonMetadata
  alias PortfolioWeb.Plugs.CSPHeader
  import Phoenix.LiveView.Router
  import Phoenix.LiveDashboard.Router
  require Logger

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
    plug CSPHeader
    plug CommonMetadata
  end

  pipeline :admin do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PortfolioWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" => "default-src 'self'"
    }

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
  if Application.compile_env(:portfolio, :environment) in [:dev, :test] do
    scope "/admin", PortfolioWeb do
      pipe_through [:admin]

      live_session :admin, on_mount: {PortfolioWeb.LiveHelpers, :admin} do
        live "/notes/new", NoteLive.Index, :new
        live "/note/:url/edit", NoteLive.Index, :edit
        live "/note/:url/show/edit", NoteLive.Show, :edit

        live "/case-study/new", CaseStudyLive.Index, :new
        live "/case-study/:url/edit", CaseStudyLive.Index, :edit
        live "/case-study/:url", CaseStudyLive.Show, :show
        live "/case-study/:url/show/edit", CaseStudyLive.Show, :edit
      end

      # Keep non-LiveView routes outside the live_session
      get "/up/", UpController, :index
      get "/up/databases", UpController, :databases
      live_dashboard "/dashboard", metrics: PortfolioWeb.Telemetry
    end
  end

  scope "/", PortfolioWeb do
    pipe_through [:browser, :locale]

    live "/", HomeLive
  end

  # Catch-all route for unmatched paths
  scope "/", PortfolioWeb do
    pipe_through :browser
    get "/up/", UpController, :index
    get "/up/databases", UpController, :databases
  end

  scope "/:locale", PortfolioWeb do
    pipe_through [:browser, :locale]

    live_session :default, on_mount: PortfolioWeb.LiveHelpers do
      live "/", HomeLive, :index
      live "/case-studies", CaseStudyLive.Index, :index
      live "/case-study/:url", CaseStudyLive.Show, :show
      live "/notes", NoteLive.Index, :index
      live "/note/:url", NoteLive.Show, :show
      live "/about", AboutLive, :index
    end
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
