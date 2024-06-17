defmodule PortfolioWeb.HomeLive do
  require Logger
  use PortfolioWeb, :live_view
  alias PortfolioWeb.Router.Helpers, as: Routes

  def mount(_params, session, socket) do
    user_locale =
      session["user_locale"] || Application.get_env(:portfolio, :default_locale)

    Gettext.put_locale(PortfolioWeb.Gettext, user_locale)

    page_number = 1

    case_studies =
      Portfolio.Content.get_all_case_studies(user_locale, page_number)

    Logger.debug("User locale assigned to socket: #{user_locale}")

    page_title =
      gettext("Zane Riley | Product Designer (Tokyo) | 10+ Years Experience")

    page_description =
      gettext(
        "Zane Riley: Tokyo Product Designer. 10+ yrs experience. Currently at Google. Worked in e-commerce, healthcare, and finance. Designed and built products for Google, Google Maps, and Google Search."
      )

    socket =
      assign(socket, case_studies: case_studies, user_locale: user_locale)

    socket =
      assign(socket, page_title: page_title, page_description: page_description)

    {:ok, socket}
  end

  # def handle_event("navigate", %{"url" => url}, socket) do
  #   {:noreply, push_patch(socket, to: url)}
  # end

  # def handle_event("change_locale", %{"locale" => locale}, socket) do
  #   Gettext.put_locale(PortfolioWeb.Gettext, locale)
  #   {:noreply, assign(socket, user_locale: locale)}
  # end

  # defp get_user_locale(session) do
  #   case session do
  #     %{"user_locale" => locale} ->
  #       Logger.debug("User locale from session: #{locale}")
  #       locale
  #     _ ->
  #       default_locale = Application.get_env(:portfolio, :default_locale)
  #       Logger.debug("Using default locale: #{default_locale}")
  #       default_locale
  #   end
  # end

  def render(assigns) do
    ~H"""
    <main class="u-container">
      <h1 class="text-2xl">
        <%= gettext("Product designer helping people beyond the screen") %>
      </h1>
      <p class="text-1xl">
        <%= gettext(
          "10+ years of experience based in Tokyo, Japan. I believe in creating products that empower people’s lives. My ultimate goal is to make things that help people shape the future they desire, not a future that is imposed upon them."
        ) %>
      </p>

      <div>
        <div class="space-y-md">
          <%= for {case_study, translations} <- @case_studies do %>
            <div class="space-y-sm">
              <.link
                navigate={
                  Routes.case_study_show_path(
                    @socket,
                    :show,
                    @user_locale,
                    case_study.url
                  )
                }
                aria-label={
                  gettext("Read more about %{title}",
                    title: translations["title"] || case_study.title
                  )
                }
                title={translations["title"] || case_study.title}
              >
                <h3>
                  <%= translations["title"] || case_study.title %>
                </h3>
              </.link>
              <p>
                <%= translations["introduction"] || case_study.introduction %>
              </p>
              <p>
                <%= case_study.read_time %> <%= ngettext(
                  "minute",
                  "minutes",
                  case_study.read_time
                ) %>
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </main>
    """
  end
end
