defmodule PortfolioWeb.Components.Footer do
  @moduledoc """
  The site footer — a colophon of how the site is made (the typefaces it's set
  in, and the site's version and change history) plus contact and meta links.

  `spec_sheet/1` is the shared "framed list of labelled facts" primitive: a
  bordered, titled box whose rows are a semantic description list (`<dl>`). The
  Typefaces sheet and the Server sheet are the *same* primitive — they differ
  only by the optional header `tag` ("NODE") and `status` dot. It's named
  `spec_sheet` (not `card`) so it reads as an *inform*-role element and leaves
  `card` free for the clickable content-preview component.
  """
  use PortfolioWeb, :html

  # Facts for the Server sheet. Every value is either a fixed fact about the
  # site or comes from Portfolio.SiteHistory; a history fact with no source is
  # nil and its row is left out, so the card never shows an invented value.
  # Header (node name + status dot) is still static: hosting is undecided
  # (see ADR 0003) and the live-data item in _PROJECT_DOCS/BACKLOG.md owns it.
  @static_status %{
    node_name: "Raspberry Pi 3B",
    node_up: true,
    # Versions of zaneriley.com since 2010, from the Internet Archive record:
    # 2010 photography site, 2011, 2015, 2017, and this codebase (2024).
    version: "5",
    stack: "Elixir · Phoenix"
  }

  @doc """
  Renders the site footer.

  `status` carries the Server sheet's facts. Leave it unset to use the site's
  own (`default_status/0`); tests pass a map with the same keys.
  """
  attr :user_locale, :string, default: "en"
  attr :current_year, :integer, required: true
  attr :status, :map, default: nil
  slot :weather

  def site_footer(assigns) do
    assigns = assign(assigns, :status, assigns.status || default_status())

    ~H"""
    <%!-- Full-bleed solid panel (Figma bg/90): the footer paints over the page's
         surface gradient instead of letting it show through. Bottom-pinning
         layout classes sit on this wrapper so the bg spans the viewport while
         content stays on the reading grid. --%>
    <div class="footer-surface mt-auto sticky top-[100vh]">
      <footer role="contentinfo" class="reading-grid pt-2xl pb-2xl">
        <%!-- Seal. The hanko SVG draws its own ring; no extra wrapper ring. --%>
        <div class="col-span-full lg:col-span-2">
          <.hanko id="footer" />
        </div>

        <%!-- Colophon: how the site is made --%>
        <section class="col-span-full lg:col-span-3 lg:col-start-3">
          <.typography
            locale={@user_locale}
            tag="h2"
            size="1xs"
            font="cheee"
            class="footer-section-head mb-1xs"
          >
            {gettext("Colophon")}
          </.typography>
          <.typography locale={@user_locale} tag="p" size="md">
            {gettext("Created on a 2014 macbook. Mocks in figma, remix freely.")}
          </.typography>

          <.spec_sheet
            label={gettext("Typefaces")}
            locale={@user_locale}
            class="mt-md"
          >
            <:row label={gettext("Titles")}>
              <span class="spec-sheet-specimen font-cardinal-fruit">
                Cardinal Fruit
              </span>
              <span class="spec-sheet-specimen-sub font-noto-serif-jp">
                Noto Serif JP
              </span>
            </:row>
            <:row label={gettext("Body")}>
              <span class="spec-sheet-specimen font-gt-flexa">GT Flexa</span>
              <span class="spec-sheet-specimen-sub font-noto-sans-jp">
                Noto Sans JP
              </span>
            </:row>
            <:row label={gettext("Mono")}>
              <.typography
                tag="span"
                font="mono"
                size="2xs"
                class="spec-sheet-specimen"
              >
                GT Flexa Mono
              </.typography>
              <.typography
                tag="span"
                font="mono"
                size="2xs"
                class="spec-sheet-specimen-sub"
              >
                GT Flexa Mono
              </.typography>
            </:row>
            <:row label={gettext("Headers")}>
              <span class="spec-sheet-specimen font-cheee">Cheee</span>
              <span class="spec-sheet-specimen-sub font-noto-sans-jp">
                Noto Sans JP
              </span>
            </:row>
          </.spec_sheet>
        </section>

        <%!-- Server: where the site runs --%>
        <section class="col-span-full lg:col-span-3">
          <.typography
            locale={@user_locale}
            tag="h2"
            size="1xs"
            font="cheee"
            class="footer-section-head mb-1xs"
          >
            {gettext("Server")}
          </.typography>
          <.typography locale={@user_locale} tag="p" size="md">
            {gettext("Self-hosted on my home server. Open source on Github.")}
          </.typography>

          <.spec_sheet
            label={@status.node_name}
            tag={gettext("Node")}
            status={if @status.node_up, do: :up, else: :down}
            locale={@user_locale}
            class="mt-md"
          >
            <:row label={gettext("Version")}>
              <.typography
                tag="span"
                font="mono"
                size="2xs"
                class="spec-sheet-value"
              >
                {@status.version}
              </.typography>
            </:row>
            <:row :if={@status.changes} label={gettext("Changes")}>
              <.typography
                tag="span"
                font="mono"
                size="2xs"
                class="spec-sheet-value"
              >
                {@status.changes}
              </.typography>
            </:row>
            <:row :if={@status.last_change_at} label={gettext("Last change")}>
              <.typography
                tag="span"
                font="mono"
                size="2xs"
                class="spec-sheet-value"
              >
                {last_change_label(@status.last_change_at)}
              </.typography>
            </:row>
            <:row label={gettext("Built with")}>
              <.typography
                tag="span"
                font="mono"
                size="2xs"
                class="spec-sheet-value"
              >
                {@status.stack}
              </.typography>
            </:row>
          </.spec_sheet>
        </section>

        <section class="col-span-full lg:col-span-3 lg:col-start-10">
          <%= if @weather != [] do %>
            {render_slot(@weather)}
          <% else %>
            <PortfolioWeb.Components.Weather.weather snapshot={
              Portfolio.Weather.current()
            } />
          <% end %>
        </section>

        <%!-- Bottom bar: copyright · links · back-to-top. One row on wide
             screens. On phones the links come first (and wrap), then © and
             back-to-top share the last row at either end. Source order is
             unchanged; only grid placement moves. Rows sit one 1xs step
             apart, about one line of this 2xs text. Links are flex (see
             .footer-link) so they line up with the bare © span. --%>
        <div class="col-span-full grid grid-cols-subgrid items-baseline gap-y-1xs">
          <.typography
            tag="span"
            font="mono"
            size="2xs"
            locale={@user_locale}
            class="caps footer-copyright col-span-2 row-start-2 lg:row-start-1"
          >
            © 2010 – {@current_year}
          </.typography>

          <nav
            class="row-start-1 col-span-full lg:col-span-6 lg:col-start-3 flex flex-wrap gap-x-md gap-y-1xs"
            aria-label={gettext("Footer")}
          >
            <%!-- TODO(footer-links): point Resume at the real PDF asset. The "(PDF)"
               suffix is a secondary annotation, so it sits one colour down from the
               link label. Leading space lives in the EN msgid; JP uses fullwidth （）. --%>
            <.link href="#" class="footer-link">
              <.typography
                tag="span"
                font="mono"
                size="2xs"
                color="inherit"
                locale={@user_locale}
                class="caps"
              >
                {gettext("Resume")}<span class="footer-muted">{gettext(" (PDF)")}</span>
              </.typography>
            </.link>
            <.link href="mailto:hello@zaneriley.com" class="footer-link">
              <.typography
                tag="span"
                font="mono"
                size="2xs"
                color="inherit"
                locale={@user_locale}
                class="caps"
              >
                {gettext("Email")}
              </.typography>
            </.link>
            <.link
              href="https://github.com/zaneriley"
              target="_blank"
              rel="noopener"
              class="footer-link"
            >
              <.typography
                tag="span"
                font="mono"
                size="2xs"
                color="inherit"
                locale={@user_locale}
                class="caps"
              >
                {gettext("Github")}
              </.typography>
            </.link>
            <.link
              href="https://www.linkedin.com/in/zaneriley/"
              target="_blank"
              rel="noopener"
              class="footer-link"
            >
              <.typography
                tag="span"
                font="mono"
                size="2xs"
                color="inherit"
                locale={@user_locale}
                class="caps"
              >
                {gettext("LinkedIn")}
              </.typography>
            </.link>
          </nav>

          <%!-- Back-to-top is an action, not a link, so it takes the action
               button primitive (a raised disc with the press light). The
               arrow sits inside a 2xs mono span so it shares the bar's text
               baseline; the label moves to aria-label. --%>
          <div class="row-start-2 col-end-[-1] col-start-[span_2] flex justify-end lg:row-start-1 lg:col-start-11 lg:col-end-13">
            <a
              href="#main-content"
              aria-label={gettext("Go to top")}
              class="footer-top action surface-raise"
            >
              <PortfolioWeb.Components.Action.light />
              <.typography
                tag="span"
                font="mono"
                size="2xs"
                color="inherit"
                locale={@user_locale}
              >
                <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                  <path d="M12 1.1C15.1 4.8 18.8 8.1 22.4 11.8L16.45 11.3Q14.7 11.15 14.65 12.95C14.45 16.3 14.55 19.2 15.45 21.6C13.3 22.5 10.35 22.85 8.2 22.4Q7.45 22.2 7.8 21.4C8.95 18.95 9.4 16.2 9.15 13Q9.05 11.5 7.65 11.6L1.55 12.2C4.9 8.6 8.65 4.95 12 1.1Z" />
                </svg>
              </.typography>
            </a>
          </div>
        </div>
      </footer>
    </div>
    """
  end

  @doc """
  The Server sheet's facts: the fixed ones plus the site's change history.
  """
  @spec default_status() :: map()
  def default_status do
    Map.merge(@static_status, Portfolio.SiteHistory.facts())
  end

  @doc """
  Says how long ago the last change landed, counted in whole calendar days
  (UTC): "today", "yesterday", "N days ago", then "N months ago" from 60 days.
  Returns `nil` when there is no timestamp.
  """
  @spec last_change_label(DateTime.t() | nil, DateTime.t()) :: String.t() | nil
  def last_change_label(at, now \\ DateTime.utc_now())
  def last_change_label(nil, _now), do: nil

  def last_change_label(%DateTime{} = at, %DateTime{} = now) do
    days = Date.diff(DateTime.to_date(now), DateTime.to_date(at))

    cond do
      days <= 0 ->
        gettext("today")

      days == 1 ->
        gettext("yesterday")

      days < 60 ->
        ngettext("%{count} day ago", "%{count} days ago", days)

      true ->
        months = div(days, 30)
        ngettext("%{count} month ago", "%{count} months ago", months)
    end
  end

  @doc """
  A framed list of labelled facts — a bordered, titled box whose rows are a
  semantic `<dl>`. Used by the footer's Typefaces and Server sheets.

  Pass the header text as `label`; the optional `tag` renders a kind-label
  before it (e.g. "NODE") and `status` (`:up` / `:down`) renders a liveness dot.
  Each `:row` slot needs a `label` and provides the value as its content.
  """
  attr :label, :string, required: true, doc: "header title for the sheet"

  attr :tag, :string,
    default: nil,
    doc: "optional kind-label rendered before the title"

  attr :status, :atom, default: nil, doc: "optional liveness dot: :up | :down"
  attr :class, :string, default: nil, doc: "extra classes on the sheet"
  attr :locale, :string, default: nil, doc: "locale for typography substitution"

  slot :row, required: true do
    attr :label, :string, required: true
  end

  def spec_sheet(assigns) do
    ~H"""
    <section class={["spec-sheet", @class]}>
      <header class="spec-sheet-head">
        <.typography
          :if={@tag}
          tag="span"
          font="mono"
          size="2xs"
          class="spec-sheet-tag"
          locale={@locale}
        >
          {@tag}
        </.typography>
        <.typography
          tag="span"
          font="mono"
          size="2xs"
          color="main"
          class="spec-sheet-title"
          locale={@locale}
        >
          {@label}
        </.typography>
        <span
          :if={@status}
          class={["spec-sheet-dot", @status == :up && "is-up"]}
          aria-hidden="true"
        ></span>
      </header>
      <dl class="spec-sheet-rows">
        <div :for={row <- @row} class="spec-sheet-row">
          <dt>
            <.typography
              tag="span"
              font="mono"
              size="2xs"
              color="suppressed"
              locale={@locale}
            >
              {row.label}
            </.typography>
          </dt>
          <dd>{render_slot(row)}</dd>
        </div>
      </dl>
    </section>
    """
  end
end
