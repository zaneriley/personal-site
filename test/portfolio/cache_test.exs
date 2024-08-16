defmodule Portfolio.CacheTest do
  use ExUnit.Case
  alias Portfolio.Cache

  # Mocking the Cachex dependency
  setup do
    :ok = Application.put_env(:portfolio, :cache, disabled: false)
    on_exit(fn -> Application.delete_env(:portfolio, :cache) end)
    :ok
  end

  describe "Cachex integration and toggling" do
    test "cache toggles between enabled and disabled states" do
      # Ensure cache is enabled and functional
      Application.put_env(:portfolio, :cache, disabled: false)
      assert {:ok, true} == Cache.put("toggle_key", "value")
      assert {:ok, "value"} == Cache.get("toggle_key")

      # Disable cache and check behavior
      Application.put_env(:portfolio, :cache, disabled: true)
      assert :cache_disabled == Cache.get("toggle_key")
      assert :cache_disabled == Cache.put("toggle_key", "new_value")
    end
  end

  describe "Cache operations" do
    test "stores and retrieves a value" do
      assert {:ok, true} == Cache.put("test_key", "test_value")
      assert {:ok, "test_value"} == Cache.get("test_key")
    end

    test "deletes a value" do
      assert {:ok, true} == Cache.put("test_key", "test_value")
      assert {:ok, true} == Cache.delete("test_key")
      assert {:ok, nil} == Cache.get("test_key")
    end
  end

  describe "concurrency tests" do
    test "handles concurrent writes and reads correctly" do
      keys = Enum.map(1..1000, &"key_#{&1}")
      values = Enum.map(1..1000, &"value_#{&1}")

      # Concurrent Writes using unique values for each key
      Enum.each(Enum.zip(keys, values), fn {key, value} ->
        Task.start(fn -> Cache.put(key, value) end)
      end)

      # Allow some time for all tasks to complete
      :timer.sleep(100)

      # Concurrent Reads
      read_results =
        Enum.map(keys, fn key ->
          Task.async(fn -> {key, Cache.get(key)} end)
        end)
        |> Enum.map(&Task.await(&1, 2000))

      assert Enum.all?(read_results, fn {key, {:ok, value}} ->
               expected_value =
                 "value_#{key |> String.split("_") |> List.last()}"

               value == expected_value
             end)
    end
  end

  describe "TTL functionality" do
    test "expires cache entries based on TTL" do
      # Setup: Put an item with a TTL of 1 second
      assert {:ok, true} == Cache.put("ttl_key", "ttl_value", ttl: 1)
      # Wait for a bit more than 1 second to ensure the TTL has passed
      :timer.sleep(1500)

      # Test: Ensure the item is expired and no longer retrievable
      assert {:ok, nil} == Cache.get("ttl_key")
    end
  end

  describe "Conditional logic" do
    test "returns :cache_disabled when cache is disabled" do
      Application.put_env(:portfolio, :cache, disabled: true)
      assert :cache_disabled == Cache.get("any_key")
      assert :cache_disabled == Cache.put("any_key", "value")
      assert :cache_disabled == Cache.delete("any_key")
    end

    test "bypasses cache on demand" do
      assert :cache_bypassed == Cache.get("any_key", bypass_cache: true)

      assert :cache_bypassed ==
               Cache.put("any_key", "value", bypass_cache: true)

      assert :cache_bypassed == Cache.delete("any_key", bypass_cache: true)
    end

    test "cache bypass does not store data" do
      assert :cache_bypassed ==
               Cache.put("bypass_key", "value", bypass_cache: true)

      # Assuming no prior value
      assert {:ok, nil} == Cache.get("bypass_key")
    end
  end

  describe "Error handling" do
    test "handles nil keys gracefully" do
      assert {:error, :invalid_key} == Cache.put(nil, "value")
      assert {:error, :invalid_key} == Cache.get(nil)
      assert {:error, :invalid_key} == Cache.delete(nil)
    end
  end

  describe "Handling edge cases for keys and values" do
    test "handles large values correctly" do
      # Creates a large string by repeating 'a' 10,000 times
      large_value = String.duplicate("a", 10_000)
      assert {:ok, true} == Cache.put("large_value_key", large_value)
      assert {:ok, large_value} == Cache.get("large_value_key")
    end

    test "handles binary keys correctly" do
      # Generates a random binary key
      binary_key = :crypto.strong_rand_bytes(50)
      assert {:ok, true} == Cache.put(binary_key, "binary_value")
      assert {:ok, "binary_value"} == Cache.get(binary_key)
    end
  end

  describe "Cache disabling functionality" do
    setup do
      Application.put_env(:portfolio, :cache, disabled: true)
      :ok
    end

    test "returns :cache_disabled when cache is disabled for ttl" do
      assert :cache_disabled == Cache.ttl("any_key")
    end

    test "returns :cache_disabled when cache is disabled for clear" do
      assert :cache_disabled == Cache.clear()
    end

    test "returns :cache_disabled when cache is disabled for bust" do
      assert :cache_disabled == Cache.bust("any_key")
    end
  end
end
