import Config

test_log_level =
  case System.get_env("PORTFOLIO_TEST_LOG_LEVEL") do
    "debug" -> :debug
    _other -> :warning
  end

test_sql_log =
  case System.get_env("PORTFOLIO_TEST_SQL_LOG") do
    "debug" -> :debug
    _other -> false
  end

config :portfolio, PortfolioWeb.Endpoint,
  token_salt: System.get_env("DEV_TOKEN_SALT"),
  secret_key_base:
    System.get_env(
      "SECRET_KEY_BASE",
      "test-only-secret-key-base-not-used-outside-tests-000000000000000000000"
    )

config :portfolio, Portfolio.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  log: test_sql_log

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: test_log_level

config :portfolio, Portfolio.Mailer, adapter: Swoosh.Adapters.Test

# You can't use mix.env in release builds, so setting this
# let's us check for the environment in the application
config :portfolio, environment: :test

config :portfolio,
  content_base_path: "test/support/fixtures"

config :portfolio, Portfolio.Content.FileManagement.Watcher,
  enabled: false,
  paths: [
    Application.get_env(:portfolio, :content_base_path)
  ]
