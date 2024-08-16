import Config

config :portfolio, PortfolioWeb.Endpoint,
  token_salt: System.get_env("DEV_TOKEN_SALT"),
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

config :portfolio, Portfolio.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :warning

config :portfolio, Portfolio.Mailer, adapter: Swoosh.Adapters.Test

# You can't use mix.env in release builds, so setting this
# let's us check for the environment in the application
config :portfolio, environment: :test

# config/test.exs
config :portfolio, :supported_locales, ["en", "ja"]
config :portfolio, :default_locale, "en"

config :portfolio, Portfolio.Content.FileSystemWatcher,
  paths: ["priv/case-study/"]
