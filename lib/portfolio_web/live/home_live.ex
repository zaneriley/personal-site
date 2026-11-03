defmodule PortfolioWeb.HomeLive do
  require Logger
  use PortfolioWeb, :live_view
  alias Portfolio.Content
  import PortfolioWeb.Components.Typography
  import PortfolioWeb.Components.ContentMetadata

  def on_mount(:default, params, session, socket) do
    {:cont,
     PortfolioWeb.LiveHelpers.on_mount(:default, params, session, socket)}
  end

  def page_title(_assigns) do
    gettext("Zane Riley | Product Designer (Tokyo) | 10+ Years Experience")
  end

  def page_description(_assigns) do
    gettext(
      "Zane Riley: Tokyo Product Designer. 10+ yrs experience. Currently at Google. Worked in e-commerce, healthcare, and finance. Designed and built products for Google, Google Maps, and Google Search."
    )
  end

  @impl true
  def mount(_params, _session, socket) do
    projects =
      Content.list(
        "project",
        [sort_by: :sort_order, sort_order: :desc],
        socket.assigns.user_locale
      )

    Logger.debug("Projects: #{inspect(projects)}")

    socket =
      assign(socket, projects: projects)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket =
      PortfolioWeb.LiveHelpers.handle_locale_and_path(socket, params, uri)

    # Re-fetch the projects with the updated locale
    projects =
      Content.list(
        "project",
        [sort_by: :sort_order, sort_order: :desc],
        socket.assigns.user_locale
      )

    socket =
      socket
      |> assign(projects: projects)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- Top lockup, words first: what (role), how (blurb), where (place).
         The portrait is off for now; it comes back on larger screens once
         its place relative to the words is settled. Copy is composed per
         locale (bespoke), not a gettext translation, so only the copy
         branches; the frame is shared.

         Line breaks are authored: whitespace-nowrap glues a phrase that must
         not split, inline-block keeps a clause whole when it fits (so a break
         lands where the sentence turns), and Japanese only breaks at <wbr />
         phrase boundaries (break-keep). The role line never wraps; app.css
         steps it down the type scale until it fits. --%>
    <section class="hero mt-1xl mb-3xl">
      <.signature class="block max-w-[34rem] mb-1xl" />
      <%= if @user_locale == "ja" do %>
        <.typography
          locale={@user_locale}
          tag="p"
          font="flexa"
          size="2xl"
          class="hero-role"
        >
          プロダクトデザイナー（<img
            src={~p"/images/logos/google-g.svg"}
            alt="Google"
            class="inline-block h-[0.85em] w-auto align-baseline"
          />）
        </.typography>
        <%!-- DRAFT JP tagline — needs native review (register/idiom). --%>
        <.typography
          locale={@user_locale}
          tag="p"
          size="md"
          class="mt-1xs text-balance break-keep"
        >
          15年以上、<wbr />戦略・<wbr />デザイン・<wbr />コード——<wbr />手段を<wbr />選ばず、<wbr />デジタルプロダクトを<wbr />つくって<wbr />きました。
        </.typography>
        <%!-- 東京 in Noto Serif JP is the emphasis — the JP twin of the
           EN Cardinal-caps. --%>
        <.typography
          locale={@user_locale}
          tag="p"
          size="md"
          class="mt-md text-balance break-keep"
        >
          <span class="inline-block">拠点は<wbr /><span class="font-noto-serif-jp font-bold">東京</span>、</span><wbr /><span class="inline-block">以前は<wbr />サンフランシスコ</span>
        </.typography>
      <% else %>
        <%!-- "Product designer" = callout (absolute white), 2xl. "at" is the
           soft tier; the G mark sits on the baseline. --%>
        <.typography locale={@user_locale} tag="p" size="2xl" class="hero-role">
          <span class="text-callout">Product designer</span>
          <span class="text-md fw-flexa-md text-deemphasized">at</span>
          <img
            src={~p"/images/logos/google-g.svg"}
            alt="Google"
            class="inline-block h-[0.85em] w-auto align-baseline"
          />
        </.typography>
        <.typography
          locale={@user_locale}
          tag="p"
          size="md"
          color="deemphasized"
          class="mt-1xs text-balance"
        >
          <span class="whitespace-nowrap">15+ years</span>
          making <span class="whitespace-nowrap">digital products</span>
          with strategy, design, code, or whatever else it takes
        </.typography>
        <.typography
          locale={@user_locale}
          tag="p"
          size="md"
          color="deemphasized"
          class="mt-md text-balance"
        >
          <span class="inline-block">
            Based in
            <span class="font-cardinal-fruit caps font-bold text-main">Tokyo</span>
          </span>
          <span class="inline-block">
            &amp; previously
            <span class="font-cardinal-fruit caps font-bold text-main whitespace-nowrap">
              San Francisco
            </span>
          </span>
        </.typography>
      <% end %>
    </section>

    <div>
      <.typography
        locale={@user_locale}
        tag="h2"
        size="1xs"
        font="cheee"
        class="mb-md"
      >
        {gettext("Work")}
      </.typography>
      <div class="grid gap-2xl">
        <%= for project <- @projects do %>
          <div class="grid gap-1xs">
            <.link
              navigate={~p"/#{@user_locale}/work/#{project.url}"}
              aria-label={
                gettext("Read more about %{title}",
                  title: project.translations["title"] || project.title
                )
              }
              title={project.translations["title"] || project.title}
            >
              <.typography locale={@user_locale} tag="h3" size="2xl" font="cardinal">
                {project.translations["title"] || project.title}
              </.typography>
            </.link>
            <.typography locale={@user_locale} tag="p" size="2xs">
              {project.translations["introduction"] ||
                project.introduction}
            </.typography>
            <.content_metadata
              read_time={project.translations["read_time"] || project.read_time}
              word_count={project.translations["word_count"] || project.word_count}
              character_count={
                project.translations["word_count"] || project.word_count
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
