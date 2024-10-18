defmodule PortfolioWeb.Navigation do
  @moduledoc """
  Main site navigation livecomponent.

  Features:
  - Logo
  - Page navigation (Case Studies, Notes, About)
  - EN/JA language switcher
  - Active page highlighting
  - Accessibility labels

  Usage:
      <.live_component module={PortfolioWeb.Navigation} id="nav" current_path={@current_path} user_locale={@locale} />

  Assigns:
  - `current_path`: Current URL path (default: "/")
  - `user_locale`: User's locale (default: "en")

  Requires gettext translations for navigation labels and language switcher text.

  Helper functions:
  - `active_class/2`: Determines active navigation item
  - `build_localized_path/2`: Generates localized paths
  """
  use PortfolioWeb, :live_component
  alias PortfolioWeb.Router.Helpers, as: Routes
  import PortfolioWeb.Components.ThemeSwitcher
  import PortfolioWeb.Components.Typography

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:current_path, fn -> assigns[:current_path] || "/" end)
      |> assign_new(:user_locale, fn -> assigns[:user_locale] || "en" end)
      |> assign_new(:selected_theme, fn ->
        assigns[:selected_theme] || "dark"
      end)

    {:ok, socket}
  end

  def render(assigns) do
    assigns =
      assign(assigns,
        en_path: build_localized_path(assigns.current_path, "en"),
        ja_path: build_localized_path(assigns.current_path, "ja")
      )

    ~H"""
    <nav role="banner" class="grid grid-cols-12 items-center w-full">
      <!-- Logo -->
      <.link
        navigate={Routes.home_path(@socket, :index, @user_locale)}
        class="col-span-2"
        aria-label={gettext("Zane Riley Portfolio Logo")}
      >
        <.typography tag="span" size="2xl" font="cardinal">Zane</.typography>
      </.link>
      <!-- Page navigation -->
      <nav role="navigation" class="col-span-6 col-start-3">
        <ul class="flex space-x-1xl">
          <li>
            <.link
              navigate={Routes.case_study_index_path(@socket, :index, @user_locale)}
              class={active_class(@current_path, :case_studies)}
            >
              <.typography tag="span" size="md">
                <%= ngettext("Case Study", "Case Studies", 2) %>
              </.typography>
            </.link>
          </li>
          <li>
            <.link
              navigate={Routes.note_index_path(@socket, :index, @user_locale)}
              class={active_class(@current_path, :notes)}
            >
              <.typography tag="span" size="md">
                <%= ngettext("Note", "Notes", 2) %>
              </.typography>
            </.link>
          </li>
          <li>
            <.link
              navigate={Routes.about_path(@socket, :index, @user_locale)}
              class={active_class(@current_path, :about)}
            >
              <.typography tag="span" size="md">
                <%= gettext("Self") %>
              </.typography>
            </.link>
          </li>
        </ul>
      </nav>
      <!-- Theme switcher -->
      <.theme_switcher class="col-start-9 col-end-11" />
      <!-- Language switcher -->
      <nav
        aria-label={gettext("Language switcher")}
        class="col-start-11 col-end-13 text-1xs"
      >
        <ul class="flex justify-end space-x-md">
          <li>
            <.link
              navigate={@en_path}
              aria-label={gettext("Switch to English")}
              aria-current={if @user_locale == "en", do: "page", else: "false"}
              class={"#{if @user_locale == "en", do: "font-bold", else: ""}"}
            >
              <.typography tag="span" size="1xs">
                English
              </.typography>
            </.link>
          </li>
          <li>
            <.link
              navigate={@ja_path}
              aria-label={gettext("Switch to Japanese")}
              aria-current={if @user_locale == "ja", do: "page", else: "false"}
              class={"#{if @user_locale == "ja", do: "font-bold", else: ""}"}
            >
              <.typography tag="span" size="1xs">
                日本語
              </.typography>
            </.link>
          </li>
        </ul>
      </nav>
    </nav>
    """
  end

  defp active_class(current_path, page) do
    if String.contains?(current_path, Atom.to_string(page)),
      do: "font-bold",
      else: ""
  end

  defp build_localized_path(current_path, locale) do
    base_path = PortfolioWeb.Layouts.remove_locale_from_path(current_path)

    if base_path == "/" do
      "/#{locale}"
    else
      "/#{locale}#{base_path}"
    end
  end
end
