defmodule Portfolio.Content.Markdown.Component.Registry do
  @moduledoc """
  Registry for components used in markdown rendering.

  This module provides a central registry for components that can be used
  in markdown content. It maps component types (atoms) to component modules
  and functions, allowing the rendering system to resolve component references.
  """

  use GenServer
  require Logger

  @type component_type :: atom()
  @type component_impl :: {module(), atom()}

  @pubsub_topic "component_registration"
  @retry_interval 100  # 100ms for fast retries, especially in tests
  @max_retries 30      # Increased from 10 to handle longer test environments
  @pubsub_check_interval 20  # Check PubSub existence every 20ms

  @doc """
  Starts the component registry.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a component with the registry.

  ## Parameters

  - `type` - The component type identifier (atom)
  - `module` - The module implementing the component
  - `opts` - Options including `:custom_function` to specify a different function

  ## Examples

      iex> Registry.register(:button, ButtonComponent)
      :ok

      iex> Registry.register(:card, CardComponent, custom_function: :card)
      :ok
  """
  @spec register(component_type(), module(), keyword()) ::
          :ok | {:error, atom()}
  def register(type, module, opts \\ [])
      when is_atom(type) and is_atom(module) do
    function = Keyword.get(opts, :custom_function, :render)
    GenServer.call(__MODULE__, {:register, type, module, function})
  end

  @doc """
  Looks up a component by type.

  ## Parameters

  - `type` - The component type identifier (atom)

  ## Examples

      iex> Registry.lookup(:button)
      {:ok, {ButtonComponent, :render}}

      iex> Registry.lookup(:unknown)
      {:error, :not_found}
  """
  @spec lookup(component_type()) ::
          {:ok, component_impl()} | {:error, :not_found}
  def lookup(type) when is_atom(type) do
    try do
      GenServer.call(__MODULE__, {:lookup, type})
    catch
      :exit, _ ->
        # If the registry is down, return not found
        {:error, :not_found}
    end
  end

  @doc """
  Lists all registered component types.

  ## Examples

      iex> Registry.list()
      [:button, :card, :typography]
  """
  @spec list() :: [component_type()]
  def list() do
    try do
      GenServer.call(__MODULE__, :list)
    catch
      :exit, _ -> []
    end
  end

  @doc """
  Unregisters a component from the registry.

  ## Parameters

  - `type` - The component type identifier (atom)

  ## Examples

      iex> Registry.unregister(:button)
      :ok
  """
  @spec unregister(component_type()) :: :ok
  def unregister(type) when is_atom(type) do
    try do
      GenServer.call(__MODULE__, {:unregister, type})
    catch
      :exit, _ -> :ok
    end
  end

  #
  # Server Implementation
  #

  @impl GenServer
  def init(_opts) do
    Logger.info("Component Registry initializing with async pattern...")
    # Initial state with retry counter
    {:ok, %{components: %{}, retries: 0, subscribed: false}, {:continue, :subscribe_pubsub}}
  end

  @impl GenServer
  def handle_continue(:subscribe_pubsub, state) do
    # Check if PubSub module exists first
    if is_pubsub_defined?() do
      # Then check if specific PubSub instance is available
      if is_pubsub_available?() do
        # PubSub is available, try to subscribe
        case safe_pubsub_subscribe() do
          :ok ->
            Logger.info("Component Registry subscribed to PubSub topic: #{@pubsub_topic}")
            {:noreply, %{state | subscribed: true}}

          {:error, reason} ->
            Logger.warning("PubSub subscription failed: #{inspect(reason)}, scheduling retry")
            schedule_retry()
            {:noreply, %{state | retries: state.retries + 1}}
        end
      else
        # PubSub not yet registered, reschedule check
        Logger.debug("PubSub not yet registered, rescheduling subscribe check")
        schedule_pubsub_check()
        {:noreply, state} # Not incrementing retries for PubSub availability checks
      end
    else
      # PubSub module not loaded, registry will operate without PubSub
      Logger.warning("PubSub module not defined, registry will operate without PubSub integration")
      {:noreply, %{state | subscribed: false}}
    end
  end

  @impl GenServer
  def handle_info(:check_pubsub, state) do
    if is_pubsub_defined?() && is_pubsub_available?() do
      # PubSub is now available, try to subscribe
      case safe_pubsub_subscribe() do
        :ok ->
          Logger.info("Component Registry subscribed to PubSub topic: #{@pubsub_topic}")
          {:noreply, %{state | subscribed: true}}

        {:error, reason} ->
          Logger.warning("PubSub subscription failed: #{inspect(reason)}, scheduling retry")
          schedule_retry()
          {:noreply, %{state | retries: state.retries + 1}}
      end
    else
      # Still not available, check again later
      schedule_pubsub_check()
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(:retry_subscribe, %{retries: retries} = state) do
    # Check if PubSub is registered before attempting to subscribe
    if is_pubsub_defined?() && is_pubsub_available?() do
      # PubSub is available, try to subscribe
      case safe_pubsub_subscribe() do
        :ok ->
          Logger.info("Component Registry successfully subscribed to PubSub on retry")
          {:noreply, %{state | retries: 0, subscribed: true}}

        {:error, reason} when retries >= @max_retries ->
          Logger.error("Max retries reached for PubSub subscription: #{inspect(reason)}")
          # Continue operating even with PubSub failures - graceful degradation
          {:noreply, %{state | retries: 0}}

        {:error, reason} ->
          Logger.warning("PubSub subscription retry failed: #{inspect(reason)}, attempting again")
          schedule_retry()
          {:noreply, %{state | retries: retries + 1}}
      end
    else
      # PubSub not yet registered, reschedule check
      Logger.debug("PubSub not yet registered on retry attempt, rescheduling subscribe check")
      schedule_pubsub_check()
      {:noreply, state} # Not incrementing retries for PubSub availability checks
    end
  end

  @impl GenServer
  def handle_info({:register_component, type, {module, function}}, state) do
    # Handle registration messages from PubSub
    components = state.components
    case Map.get(components, type) do
      nil ->
        # Register new component
        Logger.debug(
          "PubSub: Registering component #{inspect(type)} with #{inspect(module)}.#{function}"
        )

        {:noreply, %{state | components: Map.put(components, type, {module, function})}}

      {^module, _existing_function} ->
        # Update existing component from same module
        Logger.debug(
          "PubSub: Updating component #{inspect(type)} with #{inspect(module)}.#{function}"
        )

        {:noreply, %{state | components: Map.put(components, type, {module, function})}}

      {other_module, _} ->
        # Different module is trying to register same component type
        # For hot reloading, we allow replacing the component
        Logger.info(
          "PubSub: Replacing component #{inspect(type)} from #{inspect(other_module)} with #{inspect(module)}.#{function}"
        )

        {:noreply, %{state | components: Map.put(components, type, {module, function})}}
    end
  end

  @impl GenServer
  def handle_info(message, state) do
    # Ignore unknown messages
    Logger.debug(
      "Component Registry received unknown message: #{inspect(message)}"
    )

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:register, type, module, function}, _from, state) do
    components = state.components
    case Map.get(components, type) do
      nil ->
        # Component not registered yet, register it
        new_components = Map.put(components, type, {module, function})
        {:reply, :ok, %{state | components: new_components}}

      {^module, _existing_function} ->
        # Component already registered with same module, update the function
        new_components = Map.put(components, type, {module, function})
        {:reply, :ok, %{state | components: new_components}}

      {other_module, _} ->
        # Component already registered with different module
        Logger.warning(
          "Component '#{type}' already registered with #{inspect(other_module)}"
        )

        {:reply, {:error, :already_registered}, state}
    end
  end

  @impl GenServer
  def handle_call({:lookup, type}, _from, state) do
    case Map.get(state.components, type) do
      nil -> {:reply, {:error, :not_found}, state}
      component -> {:reply, {:ok, component}, state}
    end
  end

  @impl GenServer
  def handle_call(:list, _from, state) do
    {:reply, Map.keys(state.components), state}
  end

  @impl GenServer
  def handle_call({:unregister, type}, _from, state) do
    {:reply, :ok, %{state | components: Map.delete(state.components, type)}}
  end

  # Private functions
  defp schedule_retry do
    Process.send_after(self(), :retry_subscribe, @retry_interval)
  end

  defp schedule_pubsub_check do
    Process.send_after(self(), :check_pubsub, @pubsub_check_interval)
  end

  defp is_pubsub_defined? do
    Code.ensure_loaded?(Phoenix.PubSub)
  end

  defp is_pubsub_available? do
    pubsub_name = if Process.whereis(Portfolio.PubSub), do: Portfolio.PubSub, else: get_test_pubsub()
    pubsub_name != nil
  end

  defp get_test_pubsub do
    try do
      :persistent_term.get({:phoenix_pubsub, Portfolio.PubSub})
    rescue
      _ -> nil
    end
  end

  defp safe_pubsub_subscribe do
    pubsub_name = if Process.whereis(Portfolio.PubSub), do: Portfolio.PubSub, else: get_test_pubsub()

    if pubsub_name do
      try do
        Phoenix.PubSub.subscribe(pubsub_name, @pubsub_topic)
      rescue
        e -> {:error, "PubSub subscribe error: #{inspect(e)}"}
      catch
        kind, reason -> {:error, "PubSub subscribe error (#{kind}): #{inspect(reason)}"}
      end
    else
      {:error, :pubsub_not_available}
    end
  end
end
