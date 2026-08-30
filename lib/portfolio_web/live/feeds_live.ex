defmodule PortfolioWeb.FeedsLive do
  @moduledoc """
  The /feeds discovery page — the human-readable menu of subscription streams
  (the slash-page convention, feeds-spec.md): each feed's contents and volume
  described so subscribers self-select before subscribing.
  """
  use PortfolioWeb, :live_view

  alias PortfolioWeb.Feeds

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    locale = socket.assigns[:user_locale] || "en"

    {:ok,
     assign(socket,
       feeds: Feeds.all(locale),
       page_title: gettext("Feeds")
     )}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main class="u-container">
      <.typography locale={@user_locale} tag="h1" size="2xl">
        {gettext("Feeds")}
      </.typography>
      <.typography locale={@user_locale} tag="p" size="md">
        {gettext(
          "Subscribe in any feed reader. Pick the stream that matches the volume you want — each feed describes itself."
        )}
      </.typography>

      <ul class="feed-index">
        <li :for={feed <- @feeds} class="feed-index-item">
          <.typography locale={@user_locale} tag="h2" size="1xl">
            <a href={feed.path}>{feed.title}</a>
          </.typography>
          <.typography locale={@user_locale} tag="p" size="md" color="deemphasized">
            {feed.description}
          </.typography>
        </li>
      </ul>
    </main>
    """
  end
end
