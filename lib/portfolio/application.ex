defmodule Portfolio.Application do
  @moduledoc false
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Can't be a child process for some reason.
    Application.start(:yamerl)

    # Get environment for conditional setup
    env = Application.get_env(:portfolio, :environment, :dev)

    Logger.info(
      "STARTUP ENV CHECK: Environment from Application.get_env: #{inspect(env)}"
    )

    Logger.info("STARTUP ENV CHECK: Mix.env(): #{inspect(Mix.env())}")

    Logger.info(
      "STARTUP ENV CHECK: Runtime config for Portfolio.Repo: #{inspect(Application.get_env(:portfolio, Portfolio.Repo))}"
    )

    # Add more logging to understand the order of initialization
    Logger.info(
      "STARTUP ENV CHECK: Test-specific config: #{inspect(Application.get_env(:portfolio, :content_base_path))}"
    )

    children = [
      PortfolioWeb.Telemetry,
      # Make sure Repo is started early
      Portfolio.Repo,
      {DNSCluster,
       query: Application.get_env(:portfolio, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Portfolio.PubSub},
      {Finch, name: Portfolio.Finch},
      PortfolioWeb.Endpoint,
      Portfolio.Cache,
      # Make sure Registry is properly started as a child
      {Portfolio.Content.MarkdownRendering.Components.Registry, []}
    ]

    # Add file watcher for all environments except test
    children =
      if env == :test do
        children
      else
        watcher_config =
          Application.get_env(
            :portfolio,
            Portfolio.Content.FileManagement.Watcher,
            []
          )

        children ++ [{Portfolio.Content.FileManagement.Watcher, watcher_config}]
      end

    # Set supervisor options
    opts = [strategy: :one_for_one, name: Portfolio.Supervisor]

    # Start the supervisor
    result = Supervisor.start_link(children, opts)

    # Register components after application startup, but only if not in test mode
    # (tests should handle their own registration)
    register_components()

    result
  end

  @impl true
  def config_change(changed, removed) do
    PortfolioWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Register all available components with the Registry
  defp register_components do
    # Registry is now started as part of the supervision tree

    # Register components using their Definition module functionality
    alias PortfolioWeb.Components.{Typography, ColumnLayout}

    # Register each component with the new Components.Registry using their register function
    Typography.register()
    ColumnLayout.register()

    # Register any additional components here

    :ok
  end
end
