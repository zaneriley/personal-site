defmodule Portfolio.Content.MarkdownRendering.Components.Registry do
  @moduledoc """
  Registry for component modules used in markdown rendering.

  This module provides a central registry for components that can be used
  in markdown content. It maps component types (atoms) to Phoenix component
  modules and functions, allowing the rendering system to resolve component
  references in markdown to actual component implementations.
  """

  use GenServer
  require Logger

  @table_name :markdown_component_registry
  @alias_table_name :markdown_component_aliases

  @typedoc "Component type identifier"
  @type component_type :: atom()

  @typedoc "Component module and function"
  @type component_implementation :: {module(), atom()}

  @typedoc "Component metadata with documentation and attributes"
  @type component_metadata :: %{
          optional(:description) => String.t(),
          optional(:attributes) => %{atom() => attribute_spec()},
          optional(:slots) => [slot_spec()],
          optional(:examples) => [String.t()]
        }

  @typedoc "Specification for a component attribute"
  @type attribute_spec :: %{
          type: atom() | [atom()],
          required: boolean(),
          default: any(),
          description: String.t()
        }

  @typedoc "Specification for a component slot"
  @type slot_spec :: %{
          name: atom(),
          description: String.t(),
          attributes: %{atom() => attribute_spec()}
        }

  @doc """
  Starts the component registry.
  """
  def start_link(opts) do
    # Handle the case where the GenServer is already running
    case GenServer.start_link(__MODULE__, opts, name: __MODULE__) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        # Clear tables when restarting to ensure clean state
        clear_tables()
        {:ok, pid}

      other ->
        other
    end
  end

  @doc """
  Initializes the component registry.
  """
  @impl GenServer
  def init(_opts) do
    # Create ETS table for component registry
    create_tables()
    {:ok, %{}}
  end

  # Create the required ETS tables
  defp create_tables do
    # Create component registry table if it doesn't exist
    table =
      if :ets.whereis(@table_name) == :undefined do
        :ets.new(@table_name, [:set, :public, :named_table])
      else
        @table_name
      end

    # Create alias table if it doesn't exist
    alias_table =
      if :ets.whereis(@alias_table_name) == :undefined do
        :ets.new(@alias_table_name, [:set, :public, :named_table])
      else
        @alias_table_name
      end

    {table, alias_table}
  end

  # Clear all entries from the tables
  defp clear_tables do
    try do
      if :ets.whereis(@table_name) != :undefined do
        :ets.delete_all_objects(@table_name)
      end

      if :ets.whereis(@alias_table_name) != :undefined do
        :ets.delete_all_objects(@alias_table_name)
      end
    rescue
      _ -> :ok
    end
  end

  # Backward compatibility API

  @doc """
  Registers a component with the registry (simplified API for backward compatibility).

  ## Parameters

  - `type` - The component type identifier (atom)
  - `module` - The Phoenix component module

  ## Examples

      iex> Registry.register(:typography, TypographyComponent)
      :ok
  """
  @spec register(component_type(), module()) :: :ok | {:error, atom()}
  def register(type, module) when is_atom(type) and is_atom(module) do
    # Try to get the render function and metadata from the module
    function =
      if function_exported?(module, :component_function, 0),
        do: module.component_function(),
        else: :render

    metadata =
      if function_exported?(module, :component_metadata, 0),
        do: module.component_metadata(),
        else: %{}

    register_component(type, module, function, metadata)
  end

  @doc """
  Simplified lookup for backward compatibility.

  Returns just the module instead of the {module, function} tuple.
  """
  @spec lookup(component_type()) :: {:ok, module()} | {:error, :not_found}
  def lookup(type) when is_atom(type) do
    # First check aliases
    alias_lookup =
      try do
        case :ets.lookup(@alias_table_name, type) do
          [{^type, actual_type}] -> lookup_component(actual_type)
          [] -> :alias_not_found
        end
      rescue
        ArgumentError -> :alias_not_found
      end

    # If it's not an alias, do direct lookup
    case alias_lookup do
      :alias_not_found ->
        case lookup_component(type) do
          {:ok, {module, _function}} -> {:ok, module}
          {:error, :component_not_found} -> {:error, :not_found}
        end

      {:ok, {module, _function}} ->
        {:ok, module}

      {:error, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Gets metadata for a component (backward compatibility API).
  """
  @spec get_metadata(component_type()) :: {:ok, map()} | {:error, :not_found}
  def get_metadata(type) when is_atom(type) do
    case get_component_info(type) do
      {:ok, {_module, _function, metadata}} -> {:ok, metadata}
      {:error, :component_not_found} -> {:error, :not_found}
    end
  end

  @doc """
  Unregisters a component (simplified API for backward compatibility).
  """
  @spec unregister(component_type()) :: :ok
  def unregister(type) when is_atom(type) do
    # Unregister any aliases pointing to this component
    try do
      aliases =
        :ets.tab2list(@alias_table_name)
        |> Enum.filter(fn {_alias_name, target_type} -> target_type == type end)
        |> Enum.map(fn {alias_name, _} -> alias_name end)

      Enum.each(aliases, fn alias_name ->
        :ets.delete(@alias_table_name, alias_name)
      end)
    rescue
      ArgumentError -> :ok
    end

    # Unregister the component itself
    case unregister_component(type) do
      :ok -> :ok
      {:error, :component_not_found} -> :ok
    end
  end

  @doc """
  Registers an alias for an existing component.

  This allows multiple names to point to the same component implementation.
  """
  @spec register_alias(component_type(), component_type()) ::
          :ok | {:error, atom()}
  def register_alias(alias_name, target_type)
      when is_atom(alias_name) and is_atom(target_type) do
    # Verify target exists
    case lookup_component(target_type) do
      {:ok, _} ->
        # Register the alias
        try do
          :ets.insert(@alias_table_name, {alias_name, target_type})
          :ok
        rescue
          error ->
            Logger.error("Failed to register alias: #{inspect(error)}")
            {:error, :table_not_found}
        end

      {:error, _} ->
        {:error, :target_not_found}
    end
  end

  @doc """
  Registers a component with the registry.

  ## Parameters

  - `type` - The component type identifier (atom)
  - `module` - The Phoenix component module
  - `function` - The function in the module that implements the component
  - `metadata` - Optional metadata about the component

  ## Examples

      iex> Registry.register_component(:typography, TypographyComponent, :typography)
      :ok

      iex> Registry.register_component(:typography, OtherModule, :typography)
      {:error, :already_registered}
  """
  @spec register_component(
          component_type(),
          module(),
          atom(),
          component_metadata()
        ) ::
          :ok | {:error, :already_registered | atom()}
  def register_component(type, module, function, metadata \\ %{})
      when is_atom(type) and is_atom(module) and is_atom(function) and
             is_map(metadata) do
    GenServer.call(__MODULE__, {:register, type, module, function, metadata})
  end

  @doc """
  Looks up a component by type.

  ## Parameters

  - `type` - The component type identifier (atom)

  ## Examples

      iex> Registry.lookup_component(:typography)
      {:ok, {TypographyComponent, :typography}}

      iex> Registry.lookup_component(:unknown)
      {:error, :component_not_found}
  """
  @spec lookup_component(component_type()) ::
          {:ok, component_implementation()} | {:error, :component_not_found}
  def lookup_component(type) when is_atom(type) do
    try do
      case :ets.lookup(@table_name, type) do
        [{^type, module, function, _metadata}] ->
          {:ok, {module, function}}

        [] ->
          {:error, :component_not_found}
      end
    rescue
      ArgumentError -> {:error, :component_not_found}
    end
  end

  @doc """
  Gets complete information about a component, including metadata.

  ## Parameters

  - `type` - The component type identifier (atom)

  ## Examples

      iex> Registry.get_component_info(:typography)
      {:ok, {TypographyComponent, :typography, %{description: "...", attributes: %{}}}}

      iex> Registry.get_component_info(:unknown)
      {:error, :component_not_found}
  """
  @spec get_component_info(component_type()) ::
          {:ok, {module(), atom(), component_metadata()}}
          | {:error, :component_not_found}
  def get_component_info(type) when is_atom(type) do
    try do
      case :ets.lookup(@table_name, type) do
        [{^type, module, function, metadata}] ->
          {:ok, {module, function, metadata}}

        [] ->
          {:error, :component_not_found}
      end
    rescue
      ArgumentError -> {:error, :component_not_found}
    end
  end

  @doc """
  Lists all registered components.

  ## Examples

      iex> Registry.list_components()
      [:typography, :column_layout]
  """
  @spec list_components() :: [component_type()]
  def list_components do
    try do
      # Extract just the component type (first element of each tuple)
      :ets.tab2list(@table_name)
      |> Enum.map(fn {type, _module, _function, _metadata} -> type end)
    rescue
      ArgumentError -> []
    end
  end

  @doc """
  Unregisters a component from the registry.

  ## Parameters

  - `type` - The component type identifier (atom)

  ## Examples

      iex> Registry.unregister_component(:typography)
      :ok

      iex> Registry.unregister_component(:unknown)
      {:error, :component_not_found}
  """
  @spec unregister_component(component_type()) ::
          :ok | {:error, :component_not_found}
  def unregister_component(type) when is_atom(type) do
    GenServer.call(__MODULE__, {:unregister, type})
  end

  # Server callbacks

  @impl GenServer
  def handle_call({:register, type, module, function, metadata}, _from, state) do
    case :ets.lookup(@table_name, type) do
      [] ->
        # Component not registered yet, register it
        :ets.insert(@table_name, {type, module, function, metadata})
        {:reply, :ok, state}

      [{^type, existing_module, existing_function, _}] ->
        # Component already registered with same module and function, just update metadata
        if existing_module == module and existing_function == function do
          :ets.insert(@table_name, {type, module, function, metadata})
          {:reply, :ok, state}
        else
          # Component already registered with different module or function
          {:reply, {:error, :already_registered_with_different_module}, state}
        end
    end
  end

  @impl GenServer
  def handle_call({:unregister, type}, _from, state) do
    case :ets.lookup(@table_name, type) do
      [] ->
        # Component not found
        {:reply, {:error, :component_not_found}, state}

      [{^type, _, _, _}] ->
        # Component found, delete it
        :ets.delete(@table_name, type)
        {:reply, :ok, state}
    end
  end

  @doc """
  Stops the registry server.

  This is mainly used in tests to ensure clean restarts of the registry.
  """
  def stop do
    if Process.whereis(__MODULE__) do
      GenServer.stop(__MODULE__)
    end

    :ok
  end
end
