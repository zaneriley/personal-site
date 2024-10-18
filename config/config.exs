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
  default_theme: "dark",
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

config :portfolio, Portfolio.Content.Utils.MetadataCalculator,
  reading_configs: %{
    "en" => %{
      counting_method: :words,
      native_reading_speed: 238.0,
      non_native_reading_speed: 80.0,
      code_reading_speed: 50.0
    },
    "ja" => %{
      counting_method: :characters,
      native_reading_speed: 600.0,
      non_native_reading_speed: 600.0,
      code_reading_speed: 50.0
    }
  }

config :logger, :console,
  format: {LogfmtEx, :format},
  metadata: :all

config :phoenix, :json_library, Jason

config :portfolio, Portfolio.Mailer, adapter: Swoosh.Adapters.Local

config :swoosh, :api_client, false

import_config "#{Mix.env()}.exs"

config :github_webhook,
  json_library: Jason
