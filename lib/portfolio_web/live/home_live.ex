defmodule PortfolioWeb.HomeLive do
  require Logger
  use PortfolioWeb, :live_view
  alias PortfolioWeb.Router.Helpers, as: Routes
  alias Portfolio.Content
  import PortfolioWeb.LiveHelpers
  alias PortfolioWeb.DevToolbar

  def mount(_params, session, socket) do
    socket = assign_locale(socket, session)

    page_number = 1

    case_studies =
      Content.get_all_case_studies(socket.assigns.user_locale, page_number)

    socket =
      socket
      |> assign(case_studies: case_studies)
      |> assign_page_metadata(
        gettext("Zane Riley | Product Designer (Tokyo) | 10+ Years Experience"),
        gettext(
          "Zane Riley: Tokyo Product Designer. 10+ yrs experience. Currently at Google. Worked in e-commerce, healthcare, and finance. Designed and built products for Google, Google Maps, and Google Search."
        )
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket = handle_locale_and_path(socket, params, uri)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <main class="u-container">
      <%= if Application.get_env(:portfolio, :environment) == :dev do %>
        <div>
          Debug: Gettext Locale: <%= Gettext.get_locale(PortfolioWeb.Gettext) %>,
          Assign Locale: <%= @user_locale %>
        </div>
        <DevToolbar.render socket={@socket} locale={@user_locale} />
      <% end %>
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
                    title: translations[:title] || case_study.title
                  )
                }
                title={translations[:title] || case_study.title}
              >
                <h3><%= translations[:title] || case_study.title %></h3>
              </.link>
              <p class="text-1xs">
                <%= translations[:introduction] || case_study.introduction %>
              </p>
              <p class="text-1xs">
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
