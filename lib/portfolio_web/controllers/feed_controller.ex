defmodule PortfolioWeb.FeedController do
  @moduledoc """
  Serves the Atom feeds (`_PROJECT_DOCS/feeds-spec.md`). Membership comes
  from `Portfolio.Content.Feeds`; presentation from `PortfolioWeb.Feeds`;
  serialization from `PortfolioWeb.FeedXML`. Routes bypass the `:browser`
  pipeline — Atom must not inherit HTML-only plugs (layout, CSRF, CSP).
  """

  use PortfolioWeb, :controller

  alias Portfolio.Content
  alias Portfolio.Content.Utils.LanguageUtils
  alias PortfolioWeb.FeedXML
  alias PortfolioWeb.Feeds
  alias PortfolioWeb.SiteOrigin

  @doc "One Atom feed: /:locale/feeds/:feed (filename like `main.xml`)."
  def show(conn, %{"locale" => locale, "feed" => filename}) do
    with true <- locale in LanguageUtils.available_locales(),
         {:ok, feed} <- Feeds.from_filename(filename) do
      entries = Content.list_for_feed(feed, locale)
      entry_assigns = Enum.map(entries, &FeedXML.entry_assigns(&1, locale))

      body =
        FeedXML.render_feed(%{
          feed: feed,
          locale: locale,
          title: Feeds.title(feed),
          description: Feeds.description(feed),
          self_url: SiteOrigin.absolute_url(Feeds.path(feed, locale)),
          site_url: SiteOrigin.absolute_url("/#{locale}"),
          feed_updated: feed_updated(entry_assigns),
          entries: entry_assigns
        })

      etag = ~s("#{Base.encode16(:crypto.hash(:sha256, body), case: :lower)}")

      conn = put_resp_header(conn, "etag", etag)

      if etag in get_req_header(conn, "if-none-match") do
        send_resp(conn, 304, "")
      else
        conn
        |> put_resp_content_type("application/atom+xml")
        |> send_resp(200, body)
      end
    else
      _ -> send_resp(conn, 404, "Not Found")
    end
  end

  @doc "The /feed.xml convention alias."
  def root_alias(conn, _params) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: Feeds.path(:main, "en"))
  end

  # The feed-level <updated> is the newest entry's; an empty feed uses a
  # fixed epoch rather than the clock (the document must not churn).
  defp feed_updated([]), do: "2026-01-01T00:00:00Z"
  defp feed_updated([newest | _]), do: newest.updated
end
