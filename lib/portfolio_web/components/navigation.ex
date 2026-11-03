defmodule PortfolioWeb.Navigation do
  @moduledoc """
  Site identity, primary destinations, and appearance/language controls.

  One source order, home, destinations, controls, matches the wide layout
  (one row). Narrow screens show two rows, home and controls above the
  destinations; CSS moves the destinations down, and `reading-flow` follows
  the rows where supported.
  """
  use PortfolioWeb, :live_component
  import PortfolioWeb.Components.LanguageSwitch
  import PortfolioWeb.Components.ThemeSwitcher
  import PortfolioWeb.Components.Typography

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:current_path, fn -> "/" end)
      |> assign_new(:user_locale, fn -> "en" end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        destinations: destinations(assigns.user_locale),
        section:
          assigns.current_path
          |> PortfolioWeb.Layouts.remove_locale_from_path()
          |> section()
      )

    ~H"""
    <header id="site-header" class="site-header" phx-hook="Navigation">
      <div class="reading-grid site-navigation">
        <.link
          navigate={~p"/#{@user_locale}"}
          class="site-navigation-home"
          aria-label={gettext("Zane Riley Portfolio Logo")}
        >
          <.hanko />
        </.link>
        <nav
          class="site-navigation-destinations"
          aria-label={gettext("Main navigation")}
        >
          <ul>
            <li :for={{section, path, label} <- @destinations}>
              <.link
                navigate={path}
                aria-current={if @section == section, do: "page"}
              >
                <.typography
                  locale={@user_locale}
                  tag="span"
                  size="md"
                  weight={if @section == section, do: "bold", else: "regular"}
                >
                  {label}
                </.typography>
              </.link>
            </li>
          </ul>
        </nav>
        <div class="site-navigation-controls">
          <.language_switch
            current_path={@current_path}
            current_locale={@user_locale}
          />
          <.theme_switcher />
        </div>
      </div>
    </header>
    """
  end

  # {section, path, label} for each destination, in `locale`.
  defp destinations(locale) do
    [
      {"work", ~p"/#{locale}/work", gettext("Work")},
      {"notes", ~p"/#{locale}/notes", ngettext("Note", "Notes", 2)},
      {"about", ~p"/#{locale}/about", gettext("About")}
    ]
  end

  defp section(path), do: path |> String.split("/", trim: true) |> List.first()
end
