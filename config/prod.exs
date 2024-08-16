import Config

config :portfolio, PortfolioWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true

config :logger, :console,
  format: {LogfmtEx, :format},
  metadata: :all,
  level: :info

config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Portfolio.Finch

# You can't use mix.env in release builds, so setting this
# let's us check for the environment in the application
config :portfolio, environment: :prod

config :portfolio, :cache, disabled: true

config :portfolio, :csp, report_only: false
