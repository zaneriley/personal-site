defmodule PortfolioWeb.Components.Footer do
  @moduledoc """
  The site footer — a colophon of how the site is made (the typefaces it's set
  in, the machine it runs on) plus contact and meta links.

  `spec_sheet/1` is the shared "framed list of labelled facts" primitive: a
  bordered, titled box whose rows are a semantic description list (`<dl>`). The
  Typefaces sheet and the Server sheet are the *same* primitive — they differ
  only by the optional header `chip` ("NODE") and `status` dot. It's named
  `spec_sheet` (not `card`) so it reads as an *inform*-role element and leaves
  `card` free for the clickable content-preview component.
  """
  use PortfolioWeb, :html

  # Static facts for the Server sheet + the Tokyo weather mark.
  # TODO(footer-data): these are display-only for now; wire live sources later —
  #   * temp       -> Raspberry Pi thermal zone (/sys/class/thermal/thermal_zone*/temp)
  #   * deploy     -> real build/git short SHA (release stamp / compile_env)
  #   * node_up    -> healthcheck (we already serve /up)
  #   * tokyo_temp -> weather API, cached
  # The markup reads this map, so wiring real data later never touches the HEEx.
  @default_status %{
    node_name: "Raspberry Pi 3B",
    node_up: true,
    stack: "Elixir | Phoenix",
    temp: "45.2°C",
    cost: "$0.12/day",
    deploy: "passing :: 8f3a12",
    tokyo_temp: "24°c"
  }

  @doc """
  Renders the site footer.

  `status` carries the (currently static) server/weather facts; see
  `@default_status` and the TODO above for the live-data plan.
  """
  attr :user_locale, :string, default: "en"
  attr :current_year, :integer, required: true
  attr :status, :map, default: @default_status

  def site_footer(assigns) do
    ~H"""
    <footer
      role="contentinfo"
      class="mt-auto sticky top-[100vh] reading-grid pt-2xl"
    >
      <%!-- Seal --%>
      <div class="col-span-full lg:col-span-2">
        <.hanko id="footer" />
      </div>

      <%!-- Colophon: how the site is made --%>
      <section class="col-span-full lg:col-span-3 lg:col-start-3">
        <p class="footer-eyebrow">{gettext("Colophon")}</p>
        <.typography locale={@user_locale} tag="p" size="md">
          {gettext("Created on a 2014 macbook. Mocks in figma, remix freely.")}
        </.typography>

        <.spec_sheet label={gettext("Typefaces")} class="mt-md">
          <:row label={gettext("Titles")}>
            <span class="spec-sheet__specimen font-cardinal-fruit">
              Cardinal Fruit
            </span>
            <span class="spec-sheet__specimen-sub font-noto-serif-jp">
              Noto Serif JP
            </span>
          </:row>
          <:row label={gettext("Body")}>
            <span class="spec-sheet__specimen font-gt-flexa">GT Flexa</span>
            <span class="spec-sheet__specimen-sub font-noto-sans-jp">
              Noto Sans JP
            </span>
          </:row>
          <:row label={gettext("Mono")}>
            <span class="spec-sheet__specimen spec-sheet__value">
              GT Flexa Mono
            </span>
            <span class="spec-sheet__specimen-sub spec-sheet__value">
              GT Flexa Mono
            </span>
          </:row>
          <:row label={gettext("Headers")}>
            <span class="spec-sheet__specimen font-cheee">Cheee</span>
            <span class="spec-sheet__specimen-sub font-noto-sans-jp">
              Noto Sans JP
            </span>
          </:row>
        </.spec_sheet>
      </section>

      <%!-- Server: where the site runs --%>
      <section class="col-span-full lg:col-span-3">
        <p class="footer-eyebrow">{gettext("Server")}</p>
        <.typography locale={@user_locale} tag="p" size="md">
          {gettext("Self-hosted on my home server. Open source on Github.")}
        </.typography>

        <.spec_sheet
          label={@status.node_name}
          chip={gettext("Node")}
          status={if @status.node_up, do: :up, else: :down}
          class="mt-md"
        >
          <:row label={gettext("Stack")}>
            <span class="spec-sheet__value">{@status.stack}</span>
          </:row>
          <:row label={gettext("Temp")}>
            <span class="spec-sheet__value">{@status.temp}</span>
          </:row>
          <:row label={gettext("Cost")}>
            <span class="spec-sheet__value">{@status.cost}</span>
          </:row>
          <:row label={gettext("Deploy")}>
            <span class="spec-sheet__value spec-sheet__value--ok">
              {@status.deploy}
            </span>
          </:row>
        </.spec_sheet>
      </section>

      <%!-- Now in Tokyo --%>
      <section class="col-span-full lg:col-span-2 lg:col-start-11 lg:text-right">
        <p class="footer-eyebrow">{gettext("Now in Tokyo")}</p>
        <%!-- TODO(footer-data): swap for the Figma "24°c" weather mark + live temp. --%>
        <p class="spec-sheet__value" style="font-size: var(--fs-2xl)">
          {@status.tokyo_temp}
        </p>
      </section>

      <%!-- Bottom bar: copyright · links · back-to-top --%>
      <div class="col-span-full grid grid-cols-subgrid items-center gap-y-md">
        <span class="footer-eyebrow col-span-full lg:col-span-2">
          © 2011 – {@current_year}
        </span>

        <nav
          class="col-span-full lg:col-span-6 lg:col-start-3 flex flex-wrap gap-md"
          aria-label={gettext("Footer")}
        >
          <%!-- TODO(footer-links): point Resume at the real PDF asset. --%>
          <.link href="#" class="footer-eyebrow">{gettext("Resume (PDF)")}</.link>
          <.link href="mailto:hello@zaneriley.com" class="footer-eyebrow">
            {gettext("Email")}
          </.link>
          <.link
            href="https://github.com/zaneriley"
            target="_blank"
            rel="noopener"
            class="footer-eyebrow"
          >
            {gettext("Github")}
          </.link>
          <.link
            href="https://www.linkedin.com/in/zaneriley/"
            target="_blank"
            rel="noopener"
            class="footer-eyebrow"
          >
            {gettext("LinkedIn")}
          </.link>
        </nav>

        <a
          href="#main-content"
          class="footer-eyebrow col-span-full lg:col-start-11 lg:col-end-13 lg:text-right"
        >
          ↑ {gettext("Go to top")}
        </a>
      </div>
    </footer>
    """
  end

  @doc """
  A framed list of labelled facts — a bordered, titled box whose rows are a
  semantic `<dl>`. Used by the footer's Typefaces and Server sheets.

  Pass the header text as `label`; the optional `chip` renders a tag before it
  (e.g. "NODE") and `status` (`:up` / `:down`) renders a liveness dot. Each
  `:row` slot needs a `label` and provides the value as its content.
  """
  attr :label, :string, required: true, doc: "header title for the sheet"

  attr :chip, :string,
    default: nil,
    doc: "optional tag rendered before the title"

  attr :status, :atom, default: nil, doc: "optional liveness dot: :up | :down"
  attr :class, :string, default: nil, doc: "extra classes on the sheet"

  slot :row, required: true do
    attr :label, :string, required: true
  end

  def spec_sheet(assigns) do
    ~H"""
    <section class={["spec-sheet", @class]}>
      <header class="spec-sheet__head">
        <span :if={@chip} class="spec-sheet__chip">{@chip}</span>
        <span class="spec-sheet__title">{@label}</span>
        <span
          :if={@status}
          class={["spec-sheet__dot", @status == :up && "is-up"]}
          aria-hidden="true"
        >
        </span>
      </header>
      <dl class="spec-sheet__rows">
        <div :for={row <- @row} class="spec-sheet__row">
          <dt>{row.label}</dt>
          <dd>{render_slot(row)}</dd>
        </div>
      </dl>
    </section>
    """
  end
end
