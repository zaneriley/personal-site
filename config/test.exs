import Config

config :portfolio, Portfolio.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn

config :portfolio, Portfolio.Mailer, adapter: Swoosh.Adapters.Test

config :portfolio, Portfolio.Content.FileSystemWatcher,
  paths: ["priv/case-study/"]
