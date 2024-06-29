defmodule PortfolioWeb.NavComponent do
  use PortfolioWeb, :live_component
  alias PortfolioWeb.Router.Helpers, as: Routes

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:current_path, fn -> assigns[:current_path] || "/" end)
      |> assign_new(:user_locale, fn -> assigns[:user_locale] || "en" end)

    {:ok, socket}
  end

  def render(assigns) do
    assigns = assign(assigns,
      en_path: build_localized_path(assigns.current_path, "en"),
      ja_path: build_localized_path(assigns.current_path, "ja")
    )

    ~H"""
    <nav role="banner" class="flex items-center justify-between w-full">
      <!-- Logo -->
      <.link
        navigate={Routes.home_path(@socket, :index, @user_locale)}
        class="text-2xl"
        aria-label={gettext("Zane Riley Portfolio Logo")}
      >
        Logo
      </.link>
      <!-- Page navigation -->
      <nav>
        <ul class="flex items-center space-x-4">
          <li>
            <.link
              navigate={Routes.case_study_index_path(@socket, :index, @user_locale)}
              class={active_class(@current_path, :case_studies)}
            >
              <%= ngettext("Case Study", "Case Studies", 2) %>
            </.link>
          </li>
          <li>
            <.link
              navigate={Routes.note_index_path(@socket, :index, @user_locale)}
              class={active_class(@current_path, :notes)}
            >
              <%= ngettext("Note", "Notes", 2) %>
            </.link>
          </li>
          <li>
            <.link
              navigate={Routes.about_path(@socket, :index, @user_locale)}
              class={active_class(@current_path, :about)}
            >
              <%= gettext("About") %>
            </.link>
          </li>
        </ul>
      </nav>
      <!-- Language switcher -->
        <nav aria-label={gettext("Language switcher")}>
        <ul class="flex space-x-4">
          <li>
            <.link
              navigate={@en_path}
              aria-label={gettext("Switch to English")}
              aria-current={if @user_locale == "en", do: "page", else: "false"}
              class={"#{if @user_locale == "en", do: "font-bold", else: ""}"}
            >
              English
            </.link>
          </li>
          <li>
            <.link
              navigate={@ja_path}
              aria-label={gettext("Switch to Japanese")}
              aria-current={if @user_locale == "ja", do: "page", else: "false"}
              class={"#{if @user_locale == "ja", do: "font-bold", else: ""}"}
            >
              日本語
            </.link>
          </li>
        </ul>
      </nav>
    </nav>
    """
  end

  defp active_class(current_path, page) do
    if String.contains?(current_path, Atom.to_string(page)), do: "font-bold", else: ""
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
