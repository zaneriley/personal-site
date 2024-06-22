# lib/portfolio_web/live/nav_component.ex
defmodule PortfolioWeb.NavComponent do
  use PortfolioWeb, :live_component
  alias PortfolioWeb.Router.Helpers, as: Routes

  def render(assigns) do
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
        <ul>
          <li>
            <%= live_redirect(ngettext("Case Study", "Case Studies", 2),
              to: Routes.case_study_index_path(@socket, :index, @user_locale)
            ) %>
          </li>
          <li>
            <%= live_redirect(ngettext("Note", "Notes", 2),
              to: Routes.note_index_path(@socket, :index, @user_locale)
            ) %>
          </li>
          <li>
            <%= live_redirect("About",
              to: Routes.about_path(@socket, :index, @user_locale)
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
          phx-click="set_locale"
          phx-value-locale="en"
        >
          English
        </.link>
        <.link
          class={"#{if @user_locale == "ja", do: "font-bold", else: ""}"}
          phx-click="set_locale"
          phx-value-locale="ja"
        >
          日本語
        </.link>
      </div>
    </nav>
    """
  end

  def handle_event("set_locale", %{"locale" => locale}, socket) do
    # Update user locale in session and push to current page with new locale
    {:noreply,
     push_patch(socket,
       to:
         Routes.live_path(
           socket,
           socket.view,
           locale,
           socket.assigns.live_action,
           socket.assigns.params
         )
     )}
  end
end
