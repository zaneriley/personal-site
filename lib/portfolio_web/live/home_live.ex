defmodule PortfolioWeb.HomeLive do
  require Logger
  use PortfolioWeb, :live_view
  alias PortfolioWeb.Router.Helpers, as: Routes
  alias Portfolio.Content
  import PortfolioWeb.LiveHelpers
  alias PortfolioWeb.DevToolbar
  import PortfolioWeb.Components.Typography
  import PortfolioWeb.Components.ContentMetadata

  @impl true
  def mount(_params, session, socket) do
    socket = assign_locale(socket, session)

    case_studies =
      Content.list(
        "case_study",
        [sort_by: :sort_order, sort_order: :desc],
        socket.assigns.user_locale
      )

    Logger.debug("Case studies: #{inspect(case_studies)}")

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

    # Re-fetch the case studies with the updated locale
    case_studies =
      Content.list(
        "case_study",
        [sort_by: :sort_order, sort_order: :desc],
        socket.assigns.user_locale
      )

    socket =
      socket
      |> assign(case_studies: case_studies)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.typography tag="h2" size="1xl" class="uppercase">
      <%= raw(
        gettext(
          "%{role} based in %{city}",
          role:
            "<span class='font-cardinal-fruit text-callout text-3xl normal-case'>#{gettext("Digital Product Designer")}</span>",
          city:
            "<span class='font-cardinal-fruit text-callout text-3xl normal-case'>#{gettext("Tokyo")}</span>"
        )
      ) %>
    </.typography>
    <.typography tag="p" size="1xl" class="uppercase">
      <%= raw(
        gettext(
          "Solving problems for customers through %{tagline_methods} or %{tagline_else}",
          tagline_methods:
            "<br /><span class='text-callout text-2xl normal-case'>#{gettext("tagline_methods")}</span><br />",
          tagline_else:
            "<span class='font-cardinal-fruit text-callout text-2xl normal-case'>#{gettext("tagline_else")}</span>"
        )
      ) %>
    </.typography>
    <.typography tag="p" size="1xs">
      <%= gettext("Now Senior Product Designer at") %>
    </.typography>
    <.typography tag="h2" size="md">
      <%= gettext(
        "10+ years design experience. From startups to FAANG and regulated industries, I bring both breadth and depth of experience to building products people love."
      ) %><br />
    </.typography>
    <.typography tag="p" size="1xs">
      <%= gettext(
        "Based in Tokyo. I believe in creating products that empower people’s lives. My ultimate goal is to make things that help people shape the future they desire, not a future that is imposed upon them."
      ) %>

      <.link navigate={Routes.about_path(@socket, :index, @user_locale)}>
        <%= gettext("More about me.") %>
      </.link>
    </.typography>

    <div>
      <.typography tag="h2" size="1xs" font="cheee">
        <%= ngettext("Case Study", "Case Studies", 2) %>
      </.typography>
      <div class="space-y-md">
        <%= for case_study <- @case_studies do %>
          <div class="space-y-3xs">
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
                  title: case_study.translations["title"] || case_study.title
                )
              }
              title={case_study.translations["title"] || case_study.title}
            >
              <.typography tag="h3" size="2xl" font="cardinal">
                <%= case_study.translations["title"] || case_study.title %>
              </.typography>
            </.link>
            <.typography tag="p" size="2xs">
              <%= case_study.translations["introduction"] ||
                case_study.introduction %>
            </.typography>
            <.content_metadata
              read_time={
                case_study.translations["read_time"] || case_study.read_time
              }
              word_count={
                case_study.translations["word_count"] || case_study.word_count
              }
              character_count={
                case_study.translations["word_count"] || case_study.word_count
              }
              user_locale={@user_locale}
            />
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
