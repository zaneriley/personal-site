defmodule PortfolioWeb.Telemetry do
  @moduledoc """
  Emit events at various stages of an application's lifecycle.
  """

  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # SetLocale Plug Metrics
      summary("portfolio.plug.set_locale.call.duration",
        unit: {:native, :millisecond},
        description: "The time spent in the SetLocale plug's call function"
      ),
      summary("portfolio.plug.set_locale.extract_locale.duration",
        unit: {:native, :millisecond},
        description:
          "The time spent extracting the locale in the SetLocale plug"
      ),
      summary("portfolio.plug.set_locale.set_locale.duration",
        unit: {:native, :millisecond},
        description: "The time spent setting the locale in the SetLocale plug"
      ),
      distribution("portfolio.plug.set_locale.extract_locale.source",
        event_name: [:portfolio, :plug, :set_locale, :extract_locale],
        measurement: :source,
        description: "Distribution of locale sources"
      ),

      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("portfolio.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      summary("portfolio.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "Time spent decoding the data received from the database"
      ),
      summary("portfolio.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "Time spent executing the query"
      ),
      summary("portfolio.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "Time spent waiting for a database connection"
      ),
      summary("portfolio.repo.query.idle_time",
        unit: {:native, :millisecond},
        description:
          "Time spent waiting for the conn to be checked out for the query"
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {PortfolioWeb, :count_users, []}
    ]
  end
end
