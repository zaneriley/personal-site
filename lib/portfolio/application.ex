defmodule Portfolio.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    # Force creation of atoms for translatable fields at compile-time
    # This ensures that we don't run into atom table exhaustion issues

    # Can't be a child process for some reason
    if Application.get_env(:portfolio, :environment) in [:dev, :test] do
      Application.start(:yamerl)
    end

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

    children =
      if Application.get_env(:portfolio, :environment) in [:dev, :test] do
        watcher_config =
          Application.get_env(
            :portfolio,
            Portfolio.Content.FileManagement.Watcher,
            []
          )

        children ++ [{Portfolio.Content.FileManagement.Watcher, watcher_config}]
      else
        children
      end

    opts = [strategy: :one_for_one, name: Portfolio.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PortfolioWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
