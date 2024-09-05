import Config

content_base_path =
  Application.get_env(:portfolio, :content_base_path, "priv/content")

config :portfolio, PortfolioWeb.Endpoint,
  debug_errors: false,
  code_reloader: true,
  check_origin: false,
  watchers: [],
  live_reload: [
    web_console_logger: false,
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/portfolio_web/(controllers|live|components)/.*(ex|heex)$",
      ~r"#{String.trim_trailing(content_base_path, "/")}/.+\.md$"
    ]
  ],
  token_salt: System.get_env("DEV_TOKEN_SALT")

# Updating dev
# You can't use mix.env in release builds, so setting this
# let's us check for the environment in the application
config :portfolio, environment: :dev

config :portfolio, dev_routes: true

config :portfolio, Portfolio.Repo, show_sensitive_data_on_connection_error: true

config :portfolio, :csp, report_only: true

config :portfolio, :cache,
  ttl: :timer.seconds(5),
  limit: 100,
  policy: Cachex.Policy.LRU

# Optionally, to disable caching in development:
config :portfolio, :cache, disabled: true

config :logger, :console,
  format: {Portfolio.LoggerFormatter, :format},
  metadata: [:request_id, :user_id, :duration, :module, :function, :line],
  level: :debug,
  colors: [enabled: true]

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :portfolio, Portfolio.Content.FileManagement.Watcher,
  paths: ["#{content_base_path}"]

# Include HEEx debug annotations as HTML comments in rendered markup.
config :phoenix_live_view, :debug_heex_annotations, true
