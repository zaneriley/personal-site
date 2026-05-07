defmodule Portfolio.MixProject do
  use Mix.Project

  def project do
    [
      app: :portfolio,
      version: "0.4.3",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      build_path: "/mix/_build",
      deps_path: "/mix/deps",
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ],
      coveralls: [github_event_path: "/tmp/github_event.json"],
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      docs: [
        main: "Zane Riley's website documentation",
        name: "Zane Riley's website documentation",
        source_ref: "main",
        source_url: "https://github.com/zaneriley/personal-website"
      ]
    ]
  end

  def application do
    [
      mod: {Portfolio.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:cachex, "~> 4.1"},
      {:cowboy, "~> 2.14"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:earmark, "~> 1.4"},
      {:earmark_parser, "~> 1.4"},
      {:ecto_sql, "~> 3.13"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: [:dev, :test]},
      {:finch, "~> 0.21"},
      {:file_system, "~> 1.1"},
      {:floki, "~> 0.38", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:github_webhook, "~> 0.2.1"},
      {:gettext, "~> 0.26"},
      {:heroicons, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:logfmt_ex, "~> 0.4.2"},
      {:mox, "~> 1.2.0", only: :test},
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.7"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_live_dashboard, "~> 0.8.7"},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:phoenix_live_view, "~> 1.1"},
      {:plug_cowboy, "~> 2.8"},
      {:postgrex, "~> 0.22"},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
      {:swoosh, "~> 1.25"},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.3"},
      {:timex, "~> 3.7.13"},
      {:yamerl, "~> 0.10.0"},
      {:uuid, "~> 1.1"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
