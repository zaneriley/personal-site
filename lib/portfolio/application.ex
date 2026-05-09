defmodule Portfolio.Application do
  @moduledoc false

  use Application

  require Logger

  @impl true
  @spec start(Application.start_type(), term()) ::
          {:ok, pid()} | {:ok, pid(), term()} | {:error, term()}
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

    watcher_config =
      Application.get_env(
        :portfolio,
        Portfolio.Content.FileManagement.Watcher,
        []
      )

    children = children ++ watcher_children(watcher_config)

    opts = [strategy: :one_for_one, name: Portfolio.Supervisor]

    Supervisor.start_link(children, opts)
    |> tap(fn
      {:ok, _} -> Logger.info("Portfolio Application started successfully.")
      {:error, _} -> Logger.error("Portfolio Application failed to start.")
    end)
  end

  @impl true
  @spec config_change(keyword(), keyword(), keyword()) :: :ok
  def config_change(changed, _new, removed) do
    PortfolioWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp watcher_children(watcher_config) do
    paths = Keyword.get(watcher_config, :paths, [])

    if Keyword.get(watcher_config, :enabled, false) and paths != [] do
      [{Portfolio.Content.FileManagement.Watcher, watcher_config}]
    else
      []
    end
  end
end
