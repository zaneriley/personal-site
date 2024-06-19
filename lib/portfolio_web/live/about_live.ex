defmodule PortfolioWeb.AboutLive do
  require Logger
  use PortfolioWeb, :live_view
  alias PortfolioWeb.Router.Helpers, as: Routes

  def mount(_params, session, socket) do
    user_locale =
      session["user_locale"] || Application.get_env(:portfolio, :default_locale)

    Gettext.put_locale(PortfolioWeb.Gettext, user_locale)

    Logger.debug("User locale assigned to socket: #{user_locale}")

    page_title =
      gettext("Zane Riley | Product Designer (Tokyo) | 10+ Years Experience")

    page_description =
      gettext(
        "Zane Riley: Tokyo Product Designer. 10+ yrs experience. Currently at Google. Worked in e-commerce, healthcare, and finance. Designed and built products for Google, Google Maps, and Google Search."
      )

    socket =
      assign(socket, user_locale: user_locale)

    socket =
      assign(socket, page_title: page_title, page_description: page_description)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <main class="u-container">
      <h1 class="text-2xl">
        <%= gettext("Product designer helping people beyond the screen") %>
      </h1>

    </main>
    """
  end
end
