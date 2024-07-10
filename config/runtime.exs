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

config :portfolio, Portfolio.Repo,
  url: System.get_env("DATABASE_URL"),
  username: db_user,
  password: System.get_env("POSTGRES_PASSWORD", "password"),
  database: database,
  hostname: System.get_env("POSTGRES_HOST", "postgres"),
  port: String.to_integer(System.get_env("POSTGRES_PORT", "5432")),
  pool_size: String.to_integer(System.get_env("POSTGRES_POOL", "15"))

config :portfolio, :csp,
  # You can specify domains to put in the CSP header.
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
  build_url: fn ->
    scheme = System.get_env("CSP_SCHEME", "http")
    host = System.get_env("CSP_HOST", "localhost")
    port = System.get_env("CSP_PORT", "8000")

    "#{scheme}://#{host}#{if port == "80" or port == "443", do: "", else: ":#{port}"}"
  end,
  report_only: false
