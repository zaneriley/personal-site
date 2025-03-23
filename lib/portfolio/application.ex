defmodule Portfolio.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    # Can't be a child process for some reason.
    Application.start(:yamerl)

    children = [
      PortfolioWeb.Telemetry,
      Portfolio.Repo,
      {DNSCluster,
       query: Application.get_env(:portfolio, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Portfolio.PubSub},
      {Finch, name: Portfolio.Finch},
      PortfolioWeb.Endpoint,
      Portfolio.Cache
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

    # Add Registry to supervision tree
    children =
      children ++
        [{Portfolio.Content.Markdown.Component.Registry, []}]

    opts = [strategy: :one_for_one, name: Portfolio.Supervisor]
    result = Supervisor.start_link(children, opts)

    # Register components after application startup and ensure Registry is ready
    # Short delay to ensure Registry is fully started
    Process.sleep(100)
    register_components()

    result
  end

  @impl true
  def config_change(changed, _new, removed) do
    PortfolioWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Register all available components with the Registry
  defp register_components do
    # Registry is started as part of the supervision tree above

    # Register components using their Definition module functionality
    alias PortfolioWeb.Components.{Typography, ColumnLayout, Figure}

    # Register each component with the new Components.Registry using their register function
    Typography.register()
    ColumnLayout.register()
    Figure.register()

    # Register any additional components here

    :ok
  end
end
