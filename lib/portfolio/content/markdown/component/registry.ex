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
    GenServer.call(__MODULE__, {:lookup, type})
  end

  @doc """
  Lists all registered component types.

  ## Examples

      iex> Registry.list()
      [:button, :card, :typography]
  """
  @spec list() :: [component_type()]
  def list() do
    GenServer.call(__MODULE__, :list)
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
    GenServer.call(__MODULE__, {:unregister, type})
  end

  #
  # Server Implementation
  #

  @impl GenServer
  def init(_opts) do
    # Subscribe to the component registration PubSub topic
    Phoenix.PubSub.subscribe(Portfolio.PubSub, @pubsub_topic)

    # Return initial state (empty registry)
    {:ok, %{}}
  end

  @impl GenServer
  def handle_info({:register_component, type, {module, function}}, components) do
    # Handle registration messages from PubSub
    case Map.get(components, type) do
      nil ->
        # Register new component
        Logger.debug(
          "PubSub: Registering component #{inspect(type)} with #{inspect(module)}.#{function}"
        )

        {:noreply, Map.put(components, type, {module, function})}

      {^module, _existing_function} ->
        # Update existing component from same module
        Logger.debug(
          "PubSub: Updating component #{inspect(type)} with #{inspect(module)}.#{function}"
        )

        {:noreply, Map.put(components, type, {module, function})}

      {other_module, _} ->
        # Different module is trying to register same component type
        # For hot reloading, we allow replacing the component
        Logger.info(
          "PubSub: Replacing component #{inspect(type)} from #{inspect(other_module)} with #{inspect(module)}.#{function}"
        )

        {:noreply, Map.put(components, type, {module, function})}
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
  def handle_call({:register, type, module, function}, _from, components) do
    case Map.get(components, type) do
      nil ->
        # Component not registered yet, register it
        {:reply, :ok, Map.put(components, type, {module, function})}

      {^module, _existing_function} ->
        # Component already registered with same module, update the function
        {:reply, :ok, Map.put(components, type, {module, function})}

      {other_module, _} ->
        # Component already registered with different module
        Logger.warning(
          "Component '#{type}' already registered with #{inspect(other_module)}"
        )

        {:reply, {:error, :already_registered}, components}
    end
  end

  @impl GenServer
  def handle_call({:lookup, type}, _from, components) do
    case Map.get(components, type) do
      nil -> {:reply, {:error, :not_found}, components}
      component -> {:reply, {:ok, component}, components}
    end
  end

  @impl GenServer
  def handle_call(:list, _from, components) do
    {:reply, Map.keys(components), components}
  end

  @impl GenServer
  def handle_call({:unregister, type}, _from, components) do
    {:reply, :ok, Map.delete(components, type)}
  end
end
