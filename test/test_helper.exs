ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Portfolio.Repo, :manual)

# Define test components globally for all tests
defmodule Portfolio.TestComponents do
  defmodule Image do
    @moduledoc false
    def render(assigns) do
      assigns = Map.new(assigns)
      "<img src=\"#{Map.get(assigns, :src, "")}\" alt=\"#{Map.get(assigns, :alt, "")}\" />"
    end
  end
end

# Register the image component in the global registry
try do
  alias Portfolio.Content.Markdown.Component.Registry
  Registry.register(:image, Portfolio.TestComponents.Image)
rescue
  _ -> :ok  # Ignore errors during component registration
catch
  _, _ -> :ok  # Ignore errors during component registration
end
