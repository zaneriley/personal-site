import Config

config :portfolio, environment: config_env()

url_host = System.fetch_env!("URL_HOST")

config :portfolio, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

config :portfolio, PortfolioWeb.Endpoint,
  url: [
    scheme: System.get_env("URL_SCHEME", "https"),
    host: url_host,
    port: System.get_env("URL_PORT", "443")
  ],
  static_url: [
    host: System.get_env("URL_STATIC_HOST", url_host)
  ],
  http: [port: System.get_env("PORT", "8000")],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  # It is completely safe to hard code and use this salt value.
  live_view: [signing_salt: "k4yfnQW4r"]

db_user = System.get_env("POSTGRES_USER", "portfolio")
database = System.get_env("POSTGRES_DB", db_user)

database =
  if config_env() == :test do
    "#{database}_test#{System.get_env("MIX_TEST_PARTITION")}"
  else
    database
  end

# Merge the new database configuration with any existing config
# This preserves the pool setting for the test environment
repo_config = Application.get_env(:portfolio, Portfolio.Repo) || []

repo_config =
  Keyword.merge(repo_config,
    url: System.get_env("DATABASE_URL"),
    username: db_user,
    password: System.get_env("POSTGRES_PASSWORD", "password"),
    database: database,
    hostname: System.get_env("POSTGRES_HOST", "postgres"),
    port: String.to_integer(System.get_env("POSTGRES_PORT", "5432")),
    pool_size: String.to_integer(System.get_env("POSTGRES_POOL", "15"))
  )

config :portfolio, Portfolio.Repo, repo_config

config :portfolio, :github_token, System.get_env("GITHUB_TOKEN")

config :portfolio,
  github_status_context:
    System.get_env("GITHUB_STATUS_CONTEXT", "content/publication"),
  github_status_api_url:
    System.get_env("GITHUB_API_URL", "https://api.github.com"),
  github_status_owner: System.get_env("GITHUB_STATUS_OWNER"),
  github_status_repo: System.get_env("GITHUB_STATUS_REPO")

github_webhook_secret_placeholder =
  "generate-a-secret-token-for-your-repo-and-add-it-to-githubs-webhook-settings"

current_env = config_env()

github_webhook_secret =
  case {System.get_env("GITHUB_WEBHOOK_SECRET"), current_env} do
    {secret, _env}
    when is_binary(secret) and byte_size(secret) > 0 and
           secret != github_webhook_secret_placeholder ->
      secret

    {_secret, env} when env in [:dev, :test] ->
      "dev-test-github-webhook-secret"

    {_secret, _env} ->
      raise """
      environment variable GITHUB_WEBHOOK_SECRET is required in production.
      Generate a new webhook secret, configure it in GitHub, and pass it at runtime.
      """
  end

config :portfolio, github_webhook_secret: github_webhook_secret
config :github_webhook, secret: github_webhook_secret

config :portfolio, content_repo_url: System.get_env("CONTENT_REPO_URL")

default_content_base_path =
  if config_env() == :prod do
    "/app/priv/content"
  else
    "priv/content"
  end

content_base_path =
  System.get_env("CONTENT_BASE_PATH", default_content_base_path)

config :portfolio, content_base_path: content_base_path

config :portfolio, Portfolio.Content.FileManagement.Watcher,
  enabled: false,
  paths: [content_base_path]
