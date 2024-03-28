import Config

config :portfolio, PortfolioWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  token_salt: System.get_env("PROD_TOKEN_SALT")

config :logger, level: :info

config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Portfolio.Finch
