import Config

config :portfolio, PortfolioWeb.Endpoint,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [],
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/portfolio_web/(controllers|live|components)/.*(ex|heex)$",
      ~r"priv/case-study/.*(md)$"
    ]
  ],
  token_salt: System.get_env("DEV_TOKEN_SALT")

# Updating dev
config :portfolio, dev_routes: true

config :portfolio, Portfolio.Repo, show_sensitive_data_on_connection_error: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :portfolio, Portfolio.Content.FileSystemWatcher,
  paths: ["priv/case-study/"]

# Include HEEx debug annotations as HTML comments in rendered markup.
config :phoenix_live_view, :debug_heex_annotations, true
