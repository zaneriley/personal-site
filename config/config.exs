# This file is responsible for configuring your application and its
# dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :portfolio,
  ecto_repos: [Portfolio.Repo],
  generators: [timestamp_type: :utc_datetime],
  default_locale: "en",
  supported_locales: ["en", "ja"],
  static_asset_extensions: [
    "png",
    "jpg",
    "jpeg",
    "svg",
    "ico",
    "xml",
    "woff",
    "woff2"
  ]

config :portfolio, PortfolioWeb.Endpoint,
  # Enable both ipv4 and ipv6 on all interfaces. By the way, the port is
  # configured with an environment variable and it's in the runtime.exs config.
  http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: PortfolioWeb.ErrorHTML, json: PortfolioWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Portfolio.PubSub,
  live_view: [signing_salt: "aC4Hk8o2"]

config :portfolio, Portfolio.Repo, adapter: Ecto.Adapters.Postgres


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

config :logger, :console,
  format: {LogfmtEx, :format},
  metadata: :all

config :phoenix, :json_library, Jason

config :portfolio, Portfolio.Mailer, adapter: Swoosh.Adapters.Local

config :swoosh, :api_client, false

import_config "#{Mix.env()}.exs"
