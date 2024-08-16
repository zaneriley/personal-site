defmodule Portfolio.Cache do
  @moduledoc """
  Wrapper for caching operations.

  This module provides a unified interface for cache operations, supporting
  bypassing and disabling of the cache. It uses Cachex as the underlying
  cache implementation when enabled.

  The cache can be configured using the `:portfolio, :cache` application
  environment variable. Set `[disabled: true]` to disable the cache.
  """

  require Logger
  @cache_name :content_cache

  @doc """
  Returns the child specification for the cache.

  This function is used by supervisors to start the cache process.
  """
  @spec child_spec(any()) :: Supervisor.child_spec()
  def child_spec(_opts) do
    cache_opts = Application.get_env(:portfolio, :cache, [])

    if disabled?() do
      %{id: __MODULE__, start: {__MODULE__, :start_link_disabled, []}}
    else
      %{
        id: __MODULE__,
        start: {Cachex, :start_link, [@cache_name, cache_opts]}
      }
    end
  end

  @doc """
  Retrieves a value from the cache.

  Returns `{:error, :invalid_key}` if the key is nil, `:cache_bypassed` if
  bypassed, `:cache_disabled` if the cache is disabled, or the cached value.
  """
  @spec get(any(), Keyword.t()) ::
          any() | :cache_bypassed | :cache_disabled | {:error, :invalid_key}
  def get(key, opts \\ []) do
    cond do
      is_nil(key) ->
        {:error, :invalid_key}

      should_bypass?(opts) ->
        :cache_bypassed

      disabled?() ->
        :cache_disabled

      true ->
        result = Cachex.get(@cache_name, key)

        Logger.debug(
          "Cache.get called with key: #{inspect(key)}, result: #{inspect(result)}"
        )

        result
    end
  end

  def put(key, value, opts \\ []) do
    cond do
      is_nil(key) ->
        {:error, :invalid_key}

      should_bypass?(opts) ->
        :cache_bypassed

      disabled?() ->
        :cache_disabled

      true ->
        do_put(key, value, opts)
    end
  end

  defp do_put(key, value, opts) do
    ttl = Keyword.get(opts, :ttl)
    result = put_with_ttl(@cache_name, key, value, ttl)
    result
  end

  defp put_with_ttl(cache, key, value, nil), do: Cachex.put(cache, key, value)

  defp put_with_ttl(cache, key, value, ttl),
    do: Cachex.put(cache, key, value, ttl: ttl)

  @doc """
  Deletes a value from the cache.

  Returns `{:error, :invalid_key}` if the key is nil, `:cache_bypassed` if
  bypassed, `:cache_disabled` if the cache is disabled, or the result of
  Cachex.del.
  """
  @spec delete(any(), Keyword.t()) ::
          any() | :cache_bypassed | :cache_disabled | {:error, :invalid_key}
  def delete(key, opts \\ []) do
    cond do
      is_nil(key) ->
        {:error, :invalid_key}

      should_bypass?(opts) ->
        :cache_bypassed

      disabled?() ->
        :cache_disabled

      true ->
        Cachex.del(@cache_name, key)
    end
  end

  @doc """
  Checks if a key exists in the cache.

  Returns `:cache_bypassed` if bypassed, `:cache_disabled` if the cache is
  disabled, or the result of Cachex.exists?.
  """
  @spec exists?(any(), Keyword.t()) ::
          boolean() | :cache_bypassed | :cache_disabled
  def exists?(key, opts \\ []) do
    cond do
      should_bypass?(opts) ->
        :cache_bypassed

      disabled?() ->
        :cache_disabled

      true ->
        case Cachex.exists?(@cache_name, key) do
          {:ok, exists} -> exists
          _ -> false
        end
    end
  end

  @doc """
  Gets the TTL for a key in the cache.

  Returns `:cache_bypassed` if bypassed, `:cache_disabled` if the cache is
  disabled, or the result of Cachex.ttl.
  """
  @spec ttl(any(), Keyword.t()) :: integer() | :cache_bypassed | :cache_disabled
  def ttl(key, opts \\ []) do
    cond do
      should_bypass?(opts) -> :cache_bypassed
      disabled?() -> :cache_disabled
      true -> Cachex.ttl(@cache_name, key)
    end
  end

  @doc """
  Clears all entries from the cache.

  Returns `:cache_bypassed` if bypassed, `:cache_disabled` if the cache is
  disabled, or the result of Cachex.clear.
  """
  @spec clear(Keyword.t()) :: :ok | :cache_bypassed | :cache_disabled
  def clear(opts \\ []) do
    cond do
      should_bypass?(opts) -> :cache_bypassed
      disabled?() -> :cache_disabled
      true -> Cachex.clear(@cache_name)
    end
  end

  @doc """
  Busts (deletes) a specific key from the cache.

  Returns `:cache_bypassed` if bypassed, `:cache_disabled` if the cache is
  disabled, or the result of Cachex.del.
  """
  @spec bust(any(), Keyword.t()) :: :ok | :cache_bypassed | :cache_disabled
  def bust(key, opts \\ []) do
    cond do
      should_bypass?(opts) -> :cache_bypassed
      disabled?() -> :cache_disabled
      true -> Cachex.del(@cache_name, key)
    end
  end

  @doc """
  Starts a disabled cache using an Agent.

  This is used when the cache is configured to be disabled.
  """
  @spec start_link_disabled() :: Agent.on_start()
  def start_link_disabled do
    Agent.start_link(fn -> %{} end, name: @cache_name)
  end

  @doc """
  Checks if the cache is disabled based on application configuration.
  """
  @spec disabled?() :: boolean()
  def disabled? do
    Application.get_env(:portfolio, :cache, [])[:disabled] == true
  end

  @spec should_bypass?(Keyword.t()) :: boolean()
  defp should_bypass?(opts) do
    Keyword.get(opts, :bypass_cache, false)
  end
end
