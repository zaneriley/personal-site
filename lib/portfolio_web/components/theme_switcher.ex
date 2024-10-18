defmodule PortfolioWeb.Components.ThemeSwitcher do
  @moduledoc """
  A Phoenix Component for rendering a theme switcher.

  This component provides a user interface for selecting between light, dark, and system themes.
  It renders a fieldset with radio buttons for each theme option.

  ## Usage

      <.theme_switcher />

  Or with a custom class:

      <.theme_switcher class="my-custom-class" />

  Note: This component requires the "ThemeSwitcher" Phoenix LiveView JS hook to be defined
  for full functionality.
  """

  use Phoenix.Component
  import PortfolioWeb.Gettext

  @doc """
  Renders a theme switcher component.

  ## Attributes

    * `:class` - (optional) Additional CSS classes to apply to the fieldset.

  ## Examples

      <.theme_switcher />
      <.theme_switcher class="mt-4" />
  """
  attr :class, :string, default: nil

  @spec theme_switcher(map()) :: Phoenix.LiveView.Rendered.t()
  def theme_switcher(assigns) do
    themes = [
      %{value: "light", label: gettext("Light")},
      %{value: "dark", label: gettext("Dark")},
      %{value: "system", label: gettext("System")}
    ]

    ~H"""
    <fieldset
      class={["noscript", @class]}
      id="theme-switcher"
      phx-hook="ThemeSwitcher"
    >
      <legend class="sr-only"><%= gettext("Theme") %></legend>
      <form id="theme-switcher-form">
        <%= for theme <- themes do %>
          <% theme_id = "theme_#{theme.value}" %>
          <label for={theme_id}>
            <input
              type="radio"
              id={theme_id}
              name="theme"
              value={theme.value}
              checked={theme.value == "system"}
            />
            <%= theme.label %>
          </label>
        <% end %>
      </form>
    </fieldset>
    """
  end
end
