import Config

config :portfolio, Portfolio.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warning

config :portfolio, Portfolio.Mailer, adapter: Swoosh.Adapters.Test

# config/test.exs
config :portfolio, :supported_locales, ["en", "ja"]
config :portfolio, :default_locale, "en"

config :portfolio, Portfolio.Content.FileSystemWatcher,
  paths: ["priv/case-study/"]
