import Config

config :portfolio, PortfolioWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true

config :logger, :console,
  format: {LogfmtEx, :format},
  metadata: :all,
  level: :info

# Compile-time purge: prod binary should not contain :debug calls at all.
# Cuts ~hot-path call overhead and the cold-start cost of evaluating debug
# format strings. Re-enable per-call by lifting Logger.debug to Logger.info
# when a specific signal is needed in prod.
config :logger,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Portfolio.Finch

config :portfolio, Portfolio.Content.FileManagement.Watcher,
  paths: ["app/priv/content"]

# You can't use mix.env in release builds, so setting this
# let's us check for the environment in the application
config :portfolio, environment: :prod

config :portfolio, :cache, disabled: true

config :portfolio, :csp, report_only: false
