defmodule Portfolio.ComponentSupervisor do
  @moduledoc """
  Supervises the core components related to Markdown processing within the application.

  This supervisor is responsible for starting and managing the lifecycle of
  essential background processes required for handling custom Markdown components,
  ensuring they are running and restarted according to the defined strategy.

  Currently, it manages the following child:
  * `[Portfolio.Content.Markdown.Component.Registry]` - The GenServer responsible for registering and looking up available Markdown components.

  It uses a `:one_for_one` supervision strategy, meaning if a supervised component crashes, only that specific component will be restarted.
  """
  use Supervisor

  def start_link(init_arg \\ []) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Portfolio.Content.Markdown.Component.Registry, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
