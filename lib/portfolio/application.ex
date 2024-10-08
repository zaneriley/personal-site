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

    opts = [strategy: :one_for_one, name: Portfolio.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PortfolioWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
