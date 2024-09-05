defmodule Portfolio.MixProject do
  use Mix.Project

  def project do
    [
      app: :portfolio,
      version: "0.3.3-alpha.1",
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
        ignore_warnings: ".dialyzer_ignore.exs",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
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
      {:cachex, "~> 3.6"},
      {:cowboy, "~> 2.11.0"},
      {:credo, "~> 1.7.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dns_cluster, "~> 0.1.3"},
      {:earmark, "~> 1.4"},
      {:ecto_sql, "3.11.3"},
      {:excoveralls, "0.18.1", only: [:dev, :test]},
      {:finch, "0.18.0"},
      {:floki, "0.36.2", only: :test},
      {:file_system, "~> 1.0.0", only: [:dev, :test]},
      {:gettext, "0.24.0"},
      {:heroicons, "0.5.5"},
      {:jason, "~>1.4.3"},
      {:logfmt_ex, "~> 0.4.2"},
      {:mox, "~> 1.2.0", only: :test},
      {:phoenix, "1.7.14"},
      {:phoenix_ecto, "4.6.2"},
      {:phoenix_html, "4.1.1"},
      {:phoenix_live_dashboard, "0.8.4"},
      {:phoenix_live_reload, "1.5.3", only: :dev},
      {:phoenix_live_view, "0.20.17"},
      {:plug_cowboy, "~> 2.1"},
      {:postgrex, "0.18.0"},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:swoosh, "1.16.9"},
      {:telemetry_metrics, "1.0.0"},
      {:tentacat, "~> 2.4.0"},
      {:telemetry_poller, "1.1.0"},
      {:yamerl, "~> 0.10.0", only: [:dev, :test]},
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
