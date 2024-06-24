defmodule PortfolioWeb.NavComponent do
  use PortfolioWeb, :html
  alias PortfolioWeb.Router.Helpers, as: Routes

  def render_nav(assigns) do
    PortfolioWeb.NavComponent.nav(assigns)
  end

  def nav(assigns) do
    path_without_locale = assigns.conn.assigns[:path_without_locale] || "/"
    en_path = "/en#{path_without_locale}"
    ja_path = "/ja#{path_without_locale}"

    assigns = assign(assigns, en_path: en_path, ja_path: ja_path)

    ~H"""
    <nav role="banner" class="flex items-center justify-between w-full">
      <!-- Logo -->
      <.link
        navigate={Routes.home_path(@conn, :index, @user_locale)}
        class="text-2xl"
        aria-label={gettext("Zane Riley Portfolio Logo")}
      >
        Logo
      </.link>
      <!-- Page navigation -->
        <nav>
        <ul class="flex items-center space-x-4">
          <li>
            <%= live_redirect(ngettext("Case Study", "Case Studies", 2),
              to: Routes.case_study_index_path(@conn, :index, @user_locale),
              class: active_class(@conn.request_path, :case_studies)
            ) %>
          </li>
          <li>
            <%= live_redirect(ngettext("Note", "Notes", 2),
              to: Routes.note_index_path(@conn, :index, @user_locale),
              class: active_class(@conn.request_path, :notes)
            ) %>
          </li>
          <li>
            <%= live_redirect("About",
              to: Routes.about_path(@conn, :index, @user_locale),
              class: active_class(@conn.request_path, :about)
            ) %>
          </li>
        </ul>
      </nav>
      <!-- Language switcher -->
        <div
          role="region"
          aria-label={gettext("Language switcher")}
          class="flex space-x-4"
        >
          <.link
            class={"#{if @user_locale == "en", do: "font-bold", else: ""}"}
            href={@en_path}
          >
            English
          </.link>
          <.link
            class={"#{if @user_locale == "ja", do: "font-bold", else: ""}"}
            href={@ja_path}
          >
            日本語
          </.link>
        </div>
      </nav>
    """
  end

  defp active_class(current_page, page) when current_page == page, do: "font-bold"
  defp active_class(_, _), do: ""
end
