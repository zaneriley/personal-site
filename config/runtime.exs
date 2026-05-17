import Config

config :portfolio, environment: config_env()

config :portfolio, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

config :portfolio,
  canonical_origin: nil,
  noindex: true

if config_env() == :prod do
  phx_host = System.fetch_env!("PHX_HOST")
  phx_scheme = System.get_env("PHX_URL_SCHEME", "https")
  phx_port = System.get_env("PHX_URL_PORT", "443")
  force_ssl? = System.get_env("PHX_FORCE_SSL", "true") in ~w(1 true yes)

  endpoint_config = [
    url: [
      scheme: phx_scheme,
      host: phx_host,
      port: String.to_integer(phx_port)
    ],
    http: [port: String.to_integer(System.get_env("PORT", "8000"))],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
    # It is completely safe to hard code and use this salt value.
    live_view: [signing_salt: "k4yfnQW4r"]
  ]

  endpoint_config =
    if force_ssl? do
      Keyword.put(endpoint_config, :force_ssl, hsts: true)
    else
      endpoint_config
    end

  canonical_origin =
    if phx_host == "zaneriley.com" do
      "https://zaneriley.com"
    end

  config :portfolio, PortfolioWeb.Endpoint, endpoint_config

  config :portfolio,
    canonical_origin: canonical_origin,
    noindex: System.get_env("PHX_NOINDEX", "false") in ~w(1 true yes)
end

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

config :portfolio,
  content_repo_auth: [
    askpass_path:
      System.get_env(
        "CONTENT_REPO_GIT_ASKPASS",
        "/app/bin/content-git-askpass"
      ),
    https_token:
      System.get_env("CONTENT_REPO_HTTPS_TOKEN") ||
        System.get_env("CONTENT_GITHUB_TOKEN"),
    ssh_command: System.get_env("CONTENT_REPO_SSH_COMMAND"),
    username: System.get_env("CONTENT_REPO_GIT_USERNAME", "x-access-token")
  ]

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
