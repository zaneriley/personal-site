defmodule PortfolioWeb.Navigation do
  @moduledoc """
  Site identity, primary destinations, and appearance/language controls.

  One source order serves every layout: home, destinations, then controls.
  CSS places the controls above the destinations when the header uses two rows.
  """
  use PortfolioWeb, :live_component
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
        en_path: build_localized_path(assigns.current_path, "en"),
        ja_path: build_localized_path(assigns.current_path, "ja"),
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
            <li>
              <.link
                navigate={~p"/#{@user_locale}/case-studies"}
                aria-current={if @section == "case-studies", do: "page"}
              >
                <.typography
                  locale={@user_locale}
                  tag="span"
                  size="md"
                  weight={
                    if @section == "case-studies", do: "bold", else: "regular"
                  }
                >
                  {gettext("Work")}
                </.typography>
              </.link>
            </li>
            <li>
              <.link
                navigate={~p"/#{@user_locale}/notes"}
                aria-current={if @section == "notes", do: "page"}
              >
                <.typography
                  locale={@user_locale}
                  tag="span"
                  size="md"
                  weight={if @section == "notes", do: "bold", else: "regular"}
                >
                  {ngettext("Note", "Notes", 2)}
                </.typography>
              </.link>
            </li>
            <li>
              <.link
                navigate={~p"/#{@user_locale}/self"}
                aria-current={if @section == "self", do: "page"}
              >
                <.typography
                  locale={@user_locale}
                  tag="span"
                  size="md"
                  weight={if @section == "self", do: "bold", else: "regular"}
                >
                  {gettext("Self")}
                </.typography>
              </.link>
            </li>
          </ul>
        </nav>
        <div class="site-navigation-controls">
          <.theme_switcher />
          <nav
            class="site-navigation-languages"
            aria-label={gettext("Language switcher")}
          >
            <ul>
              <li>
                <.link
                  href={@en_path}
                  lang="en"
                  hreflang="en"
                  aria-current={if @user_locale == "en", do: "true"}
                >
                  <.typography
                    locale="en"
                    tag="span"
                    size="1xs"
                    weight={if @user_locale == "en", do: "bold", else: "regular"}
                  >
                    English
                  </.typography>
                </.link>
              </li>
              <li>
                <.link
                  href={@ja_path}
                  lang="ja"
                  hreflang="ja"
                  aria-current={if @user_locale == "ja", do: "true"}
                >
                  <.typography
                    locale="ja"
                    tag="span"
                    size="1xs"
                    weight={if @user_locale == "ja", do: "bold", else: "regular"}
                  >
                    日本語
                  </.typography>
                </.link>
              </li>
            </ul>
          </nav>
        </div>
      </div>
    </header>
    """
  end

  defp section(path), do: path |> String.split("/", trim: true) |> List.first()

  defp build_localized_path(current_path, locale) do
    base_path = PortfolioWeb.Layouts.remove_locale_from_path(current_path)

    if base_path == "/" do
      "/#{locale}"
    else
      "/#{locale}#{base_path}"
    end
  end
end
