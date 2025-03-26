defmodule Portfolio.TestComponents do
  @moduledoc """
  Defines test components and helpers for component registration in tests.
  """

  defmodule Image do
    @moduledoc false
    def render(assigns) do
      assigns = Map.new(assigns)

      "<img src=\"#{Map.get(assigns, :src, "")}\" alt=\"#{Map.get(assigns, :alt, "")}\" />"
    end
  end

  # Registry management functions for tests
  def ensure_essential_components_registered(retries \\ 5) do
    alias Portfolio.Content.Markdown.Component.Registry

    # Start by ensuring the application is started
    Application.ensure_all_started(:portfolio)

    # Sleep briefly to allow application to initialize
    Process.sleep(100)

    # Attempt to register the image component
    case Registry.register(:image, Portfolio.TestComponents.Image) do
      :ok ->
        # Registration successful
        :ok

      {:error, :already_registered} ->
        # Already registered, also fine
        :ok

      _error when retries > 0 ->
        # Failed to register, retry after a delay
        Process.sleep(100)
        ensure_essential_components_registered(retries - 1)

      _error ->
        # Out of retries
        raise "Failed to register essential test components after multiple attempts"
    end
  end
end
