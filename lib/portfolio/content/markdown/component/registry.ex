defmodule Portfolio.Content.Markdown.Component.Registry do
  @moduledoc """
  Registry for components used in markdown rendering.

  This module provides a central registry for components that can be used
  in markdown content. It maps component types (atoms) to component modules
  and functions, allowing the rendering system to resolve component references.

  Registration is synchronous: callers (typically `Definition.__after_compile__/2`)
  invoke `register/3`, which routes through `GenServer.call/3` to the
  `handle_call({:register, ...}, ...)` clause. The registry's mutable state is
  the only justification for the GenServer wrapper — it serializes writes so
  module/type collisions resolve deterministically.
  """

  use GenServer
  require Logger

  @type component_type :: atom()
  @type component_impl :: {module(), atom()}

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

  @doc """
  Clears all registered components. Intended primarily for testing.

  ## Examples

      iex> Registry.clear_all_components()
      :ok
  """
  @spec clear_all_components() :: :ok
  def clear_all_components() do
    try do
      GenServer.call(__MODULE__, :clear_all)
    catch
      :exit, _ -> :ok
    end
  end

  #
  # Server Implementation
  #

  @impl GenServer
  def init(_opts) do
    Logger.info("Component Registry initializing")
    {:ok, %{components: %{}}}
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
        # Component already registered with different module — replace it
        # (hot-reload semantics: a re-compiled module wins over the stale binding)
        Logger.info(
          "Replacing component #{inspect(type)} from #{inspect(other_module)} with #{inspect(module)}.#{function}"
        )

        new_components = Map.put(components, type, {module, function})
        {:reply, :ok, %{state | components: new_components}}
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

  @impl GenServer
  def handle_call(:clear_all, _from, state) do
    Logger.debug("Clearing all components from registry")
    {:reply, :ok, %{state | components: %{}}}
  end

  @impl GenServer
  def handle_info(message, state) do
    Logger.debug(
      "Component Registry received unknown message: #{inspect(message)}"
    )

    {:noreply, state}
  end
end
