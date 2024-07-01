defmodule PortfolioWeb.Router do
  use PortfolioWeb, :router
  alias PortfolioWeb.Plugs.SetLocale
  alias PortfolioWeb.Plugs.LocaleRedirection
  alias PortfolioWeb.Plugs.CommonMetadata
  import Phoenix.LiveView.Router
  import Phoenix.LiveDashboard.Router
  require Logger

  defp put_csp_header(conn, _opts) do
    csp_config = Application.get_env(:portfolio, :csp, [])
    scheme = csp_config[:scheme] || "http"
    host = csp_config[:host] || "localhost"
    port = csp_config[:port] || "8000"

    base_url =
      "#{scheme}://#{host}#{if port in ["80", "443"], do: "", else: ":#{port}"}"

    ws_scheme = if scheme == "https", do: "wss", else: "ws"

    ws_url =
      "#{ws_scheme}://#{host}#{if port in ["80", "443"], do: "", else: ":#{port}"}"

    additional_hosts =
      if Mix.env() == :dev,
        do: "http://0.0.0.0:#{port} https://0.0.0.0:#{port}",
        else: ""

    additional_ws =
      if Mix.env() == :dev, do: "ws://0.0.0.0:* wss://0.0.0.0:*", else: ""

    frame_src = if Mix.env() == :dev, do: "'self'", else: "'none'"

    csp =
      "default-src 'self' #{base_url} #{additional_hosts}; " <>
        "script-src 'self' #{base_url} #{additional_hosts} 'unsafe-inline'; " <>
        "style-src 'self' #{base_url} #{additional_hosts} 'unsafe-inline'; " <>
        "img-src 'self' #{base_url} #{additional_hosts} data:; " <>
        "font-src 'self' #{base_url} #{additional_hosts}; " <>
        "connect-src 'self' #{base_url} #{additional_hosts} #{ws_url} #{additional_ws}; " <>
        "frame-src #{frame_src}; " <>
        "object-src 'none'; " <>
        "base-uri 'self'; " <>
        "form-action 'self'; " <>
        "frame-ancestors 'none';" <>
        if @compile_env == :prod, do: " upgrade-insecure-requests;", else: ""

    header_name =
      if csp_config[:report_only],
        do: "content-security-policy-report-only",
        else: "content-security-policy"

    put_resp_header(conn, header_name, csp)
  end

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
    plug :put_csp_header
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
  if Mix.env() in [:dev, :test] do
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
