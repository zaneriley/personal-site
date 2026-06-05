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
    case_studies =
      Content.list(
        "case_study",
        [sort_by: :sort_order, sort_order: :desc],
        socket.assigns.user_locale
      )

    Logger.debug("Case studies: #{inspect(case_studies)}")

    socket =
      assign(socket, case_studies: case_studies)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket =
      PortfolioWeb.LiveHelpers.handle_locale_and_path(socket, params, uri)

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
    <section class="hero mb-3xl flex flex-col gap-2xl lg:flex-row lg:items-start lg:justify-between">
      <div class="hero-lede">
        <.signature class="block max-w-[34rem] mb-1xl" />
        <%= if @user_locale == "ja" do %>
          <%!-- JP hero (Option A): rooted/editorial; 東京 in Noto Serif JP is the
               emphasis — the JP twin of the EN Cardinal-caps. Copy is composed
               per-locale (bespoke), not a gettext translation of the EN. --%>
          <.typography locale={@user_locale} tag="p" font="flexa" size="2xl">
            プロダクトデザイナー（<img
              src={~p"/images/logos/google-g.svg"}
              alt="Google"
              class="inline-block h-[0.85em] w-auto align-baseline"
            />）
          </.typography>
          <.typography locale={@user_locale} tag="p" size="1xl">
            拠点は<span class="font-noto-serif-jp font-bold">東京</span>、以前はサンフランシスコ
          </.typography>
          <%!-- DRAFT JP tagline — needs native review (register/idiom). --%>
          <.typography locale={@user_locale} tag="p" size="md">
            15年以上、戦略・デザイン・コード——手段を選ばず、デジタルプロダクトをつくってきました。
          </.typography>
        <% else %>
          <%!-- The line gets the 2xl optical regular automatically (fw-flexa-2xl);
               "Product designer" takes the 2xl bold rung, so "at" stays lighter
               than the role. Weights come from the calibrated optical curve
               (_type-weight.css). The G mark sits on the text baseline. --%>
          <.typography locale={@user_locale} tag="p" size="2xl">
            <span class="text-callout fw-flexa-2xl-bold">Product designer</span> at
            <img
              src={~p"/images/logos/google-g.svg"}
              alt="Google"
              class="inline-block h-[0.85em] w-auto align-baseline"
            />
          </.typography>
          <.typography locale={@user_locale} tag="p" size="1xl">
            Based in
            <span class="font-cardinal-fruit uppercase font-bold tracking-[0.02em] text-callout">
              Tokyo
            </span>
            &amp; previously
            <span class="font-cardinal-fruit uppercase font-bold tracking-[0.02em] text-callout">
              San Francisco
            </span>
          </.typography>
          <.typography locale={@user_locale} tag="p" size="md">
            +15 years experience in making digital products using strategy, design, code or whatever else it takes
          </.typography>
        <% end %>
      </div>

      <%!-- Portrait — DRAFT stub. TODO(hero): srcset/responsive pipeline + the
           generated border treatment; swap the draft for the real asset. --%>
      <img
        src={~p"/images/portrait-draft.jpg"}
        alt={gettext("Portrait of Zane Riley")}
        width="468"
        height="714"
        class="hero-photo w-full max-w-[15rem] shrink-0 rounded-2xl lg:max-w-[17rem]"
      />
    </section>

    <div>
      <.typography locale={@user_locale} tag="h2" size="1xs" font="cheee">
        {ngettext("Case Study", "Case Studies", 2)}
      </.typography>
      <div class="space-y-md">
        <%= for case_study <- @case_studies do %>
          <div class="space-y-3xs">
            <.link
              navigate={~p"/#{@user_locale}/case-study/#{case_study.url}"}
              aria-label={
                gettext("Read more about %{title}",
                  title: case_study.translations["title"] || case_study.title
                )
              }
              title={case_study.translations["title"] || case_study.title}
            >
              <.typography locale={@user_locale} tag="h3" size="2xl" font="cardinal">
                {case_study.translations["title"] || case_study.title}
              </.typography>
            </.link>
            <.typography locale={@user_locale} tag="p" size="2xs">
              {case_study.translations["introduction"] ||
                case_study.introduction}
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
