defmodule PortfolioWeb.Feeds do
  @moduledoc """
  The web-facing half of the feeds contract (`_PROJECT_DOCS/feeds-spec.md`):
  maps the Content-owned feed names to subscriber-facing titles, descriptions,
  and paths. The single source for feed routes, the /feeds page, and head
  autodiscovery links — layouts never hardcode feed names or URLs.

  Membership (which entries are in a feed) is Content's: see
  `Portfolio.Content.Feeds`.
  """

  use Gettext, backend: PortfolioWeb.Gettext

  use Phoenix.VerifiedRoutes,
    endpoint: PortfolioWeb.Endpoint,
    router: PortfolioWeb.Router

  @path_segments %{
    "main" => :main,
    "case-studies" => :case_studies,
    "notes" => :notes,
    "everything" => :everything
  }

  @doc "Resolves a path filename like `main.xml` to its feed name."
  @spec from_filename(String.t()) :: {:ok, atom()} | :error
  def from_filename(filename) do
    with [segment, "xml"] <- String.split(filename, "."),
         {:ok, feed} <- Map.fetch(@path_segments, segment) do
      {:ok, feed}
    else
      _ -> :error
    end
  end

  @doc "The Atom document path for a feed in a locale."
  @spec path(atom(), String.t()) :: String.t()
  def path(feed, locale) do
    ~p"/#{locale}/feeds/#{segment(feed) <> ".xml"}"
  end

  @doc "Subscriber-facing title for a feed (translated)."
  @spec title(atom()) :: String.t()
  def title(:main), do: gettext("Zane Riley — the work")
  def title(:case_studies), do: gettext("Zane Riley — case studies")
  def title(:notes), do: gettext("Zane Riley — all notes")
  def title(:everything), do: gettext("Zane Riley — everything")

  @doc "Subscriber-facing volume description for a feed (translated)."
  @spec description(atom()) :: String.t()
  def description(:main),
    do:
      gettext(
        "Case studies and selected long-form notes. Low volume — the default subscription."
      )

  def description(:case_studies), do: gettext("Only the case studies.")

  def description(:notes),
    do: gettext("Every note, short and long. Higher volume.")

  def description(:everything),
    do: gettext("Every published entry — the opt-in firehose.")

  @doc "All feeds with their presentation, for the /feeds page and autodiscovery."
  @spec all(String.t()) :: [map()]
  def all(locale) do
    for {_segment, feed} <- @path_segments do
      %{
        name: feed,
        title: title(feed),
        description: description(feed),
        path: __MODULE__.path(feed, locale)
      }
    end
  end

  @doc """
  The feeds a page should advertise in its head: always the locale's main
  feed; section index pages additionally their section's. Returns
  `{title, path}` tuples for `<link rel="alternate">` rendering — layouts
  never hardcode feed names or URLs.
  """
  @spec autodiscovery(String.t(), String.t()) :: [{String.t(), String.t()}]
  def autodiscovery(locale, request_path) do
    section =
      cond do
        String.ends_with?(request_path, "/notes") -> [:notes]
        String.ends_with?(request_path, "/case-studies") -> [:case_studies]
        true -> []
      end

    for feed <- [:main | section],
        do: {title(feed), __MODULE__.path(feed, locale)}
  end

  defp segment(feed) do
    {segment, _} = Enum.find(@path_segments, fn {_s, f} -> f == feed end)
    segment
  end
end
