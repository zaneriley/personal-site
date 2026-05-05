defmodule Portfolio.Application do
  require Logger
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    Logger.info("Starting Portfolio Application...")

    # Can't be a child process for some reason.
    Application.start(:yamerl)

    children = [
      PortfolioWeb.Telemetry,
      # Start Repo first (database)
      Portfolio.Repo,
      # Then PubSub
      {Phoenix.PubSub, name: Portfolio.PubSub},
      # Then ComponentSupervisor (which depends on PubSub)
      Portfolio.ComponentSupervisor,
      # Other services that don't have critical dependencies
      Portfolio.Cache,
      {Finch, name: Portfolio.Finch},
      PortfolioWeb.Endpoint
    ]

    # Add file watcher for all environments
    watcher_config =
      Application.get_env(
        :portfolio,
        Portfolio.Content.FileManagement.Watcher,
        []
      )

    children =
      children ++ [{Portfolio.Content.FileManagement.Watcher, watcher_config}]

    opts = [strategy: :one_for_one, name: Portfolio.Supervisor]

    Supervisor.start_link(children, opts)
    |> tap(fn
      {:ok, _} -> Logger.info("Portfolio Application started successfully.")
      {:error, _} -> Logger.error("Portfolio Application failed to start.")
    end)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PortfolioWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
