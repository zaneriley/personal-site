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
  # Header names the site itself, not the machine: hosting is undecided
  # (see ADR 0003). The status dot is still static; the live-data item in
  # _PROJECT_DOCS/BACKLOG.md owns it.
  @static_status %{
    node_name: "zaneriley.com",
    node_up: true,
    # Versions of zaneriley.com since 2010, from the Internet Archive record:
    # 2010 photography site, 2011, 2015, 2017, and this codebase (2024).
    version: "5",
    stack: [:elixir, :phoenix]
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
            <%!-- Raw spans like the other rows, with the classes the
                 typography component would give mono 2xs (face, size-matched
                 weight, size), but without its trimmed inline-block box, which
                 kept the two names on one line. --%>
            <:row label={gettext("Mono")}>
              <span class="spec-sheet-specimen font-gt-flexa-mono fw-flexa-2xs text-2xs">
                GT Flexa Mono
              </span>
              <span class="spec-sheet-specimen-sub font-gt-flexa-mono fw-flexa-2xs text-2xs">
                GT Flexa Mono
              </span>
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
              <span class="tech-badges">
                <.tech_badge :for={tech <- @status.stack} tech={tech} />
              </span>
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

  # Brand marks from Simple Icons (CC0), drawn in a 24-unit box, and each
  # project's own brand colour (see _footer.css .tech-badge-*).
  @tech %{
    elixir:
      {"Elixir",
       "M19.793 16.575c0 3.752-2.927 7.426-7.743 7.426-5.249 0-7.843-3.71-7.843-8.29 0-5.21 3.892-12.952 8-15.647a.397.397 0 0 1 .61.371 9.716 9.716 0 0 0 1.694 6.518c.522.795 1.092 1.478 1.763 2.352.94 1.227 1.637 1.906 2.644 3.842l.015.028a7.107 7.107 0 0 1 .86 3.4z"},
    phoenix:
      {"Phoenix",
       "m9.012 15.241-.188-.036c-1.34-.248-2.186-1.06-2.588-2.334-.25-.794.204-1.38 1.038-1.416.682-.032 1.15.36 1.562.816.532.588 1.02 1.216 1.542 1.814.754.86 1.64 1.412 2.854 1.24a5.404 5.404 0 0 0 2.86-1.308c.124-.108.26-.2.392-.302l-.084-.098a6.034 6.034 0 0 1-2.12.252c-1.092-.054-2.132-.282-3.064-.882-.848-.548-1.476-1.28-1.774-2.26-.24-.79.252-1.344 1.072-1.23.313.049.606.187.842.398.2.168.39.346.594.51.958.77 2.294.812 3.508-.022-1.996-.01-3.354-1.108-4.548-2.5-.466-.544-.922-1.1-1.4-1.636-.92-1.038-1.944-1.952-3.346-2.264-1.79-.398-3.518-.136-5.176.622A4.214 4.214 0 0 0 0 5.217h.352c.836-.022 1.464.35 1.916 1.034.328.498.482 1.06.6 1.64.176.86.086 1.734.188 2.598.26 2.22 1.394 3.768 3.506 4.56.774.292 1.568.39 2.45.19v.002zM3.674 5.113c-.334.084-.6-.05-.874-.328.47-.118.886-.164 1.332-.18a.562.562 0 0 1-.458.508zm10.938 12.96c-.03-.212-.212-.306-.356-.42-.634-.492-1.378-.668-2.164-.682a4.08 4.08 0 0 1-1.378-.208c-.204-.076-.43-.174-.426-.436.006-.266.238-.34.448-.404.174-.052.352-.084.548-.13-.5-.32-.988-.364-1.636-.102-1.024.41-2.032.36-3.052-.006-.574-.208-1.086-.534-1.618-.824l-.026.02c.44.722 1.038 1.304 1.71 1.8 1.296.96 2.712 1.53 4.37 1.276a22.8 22.8 0 0 1 1.614-.19c.676-.054 1.32.136 1.966.308v-.002zm-3.124-10.37c-.036-.026-.07-.09-.144-.024a5.258 5.258 0 0 0 2.284 1.776c1.488.604 3 .708 4.544.174 1.2-.414 2.06-.01 2.508 1.156.066-1.352-.73-2.338-1.996-2.53-.712-.11-1.37.128-2.038.32-1.856.54-3.584.274-5.16-.872h.002zm9.256 5.272.726.064c-.546-.48-1.212-.52-1.888-.48-1.026.058-1.766.65-2.44 1.356-.594.624-1.13 1.324-2.016 1.574l.02.04c.12.002.24.008.36.002 1.288-.058 2.5-.33 3.464-1.264.306-.294.576-.62.87-.926.226-.258.562-.394.904-.366zm-2.992-1.596c-.96.084-1.794.48-2.58 1.006-.602.404-1.248.594-1.972.468-.128-.022-.258-.04-.384-.058l-.006.054c.046.024.092.05.14.07.12.048.24.106.364.136 1.396.33 2.732.16 3.936-.618.76-.49 1.546-.582 2.398-.456.086.014.172.028.258.036.08.008.164.088.272 0a3.454 3.454 0 0 0-2.426-.638zm-3.434-3.26a2.68 2.68 0 0 0 1.534-.364c-.154.014-.22.014-.282.026a2.296 2.296 0 0 1-1.96-.472l-.646-.5c-.856-.652-1.836-.872-2.91-.852.018.052.02.088.038.106 1.168 1.18 2.52 1.996 4.226 2.054v.002zm8.452 6.06c-.724-.72-1.694-.81-2.59-.186.594.028 1.04.216 1.4.592.128.134.262.26.404.378.548.44 1.474.46 2.016.052-.636-.248-.636-.248-1.23-.838v.002zm-7.198 5.486c-.634-1.18-1.7-1.448-2.936-1.368.364.1.708.26 1.02.474.286.2.526.448.764.702.472.504 1.208.812 1.696.708-.224-.14-.546-.514-.546-.514h-.012l.008.006.004.018c.004-.02.006-.016.008-.01h.02l-.028-.012v.01l.01.004s.114.208-.008-.018z"}
  }

  attr :tech, :atom, required: true, values: Map.keys(@tech)

  # A GitHub-README-style badge: the project's mark and name on its brand colour.
  defp tech_badge(assigns) do
    {name, path} = Map.fetch!(@tech, assigns.tech)
    assigns = assign(assigns, name: name, path: path)

    ~H"""
    <span class={["tech-badge", "tech-badge-#{@tech}"]}>
      <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
        <path d={@path} />
      </svg>
      <.typography tag="span" font="mono" size="2xs" color="inherit">
        {@name}
      </.typography>
    </span>
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
