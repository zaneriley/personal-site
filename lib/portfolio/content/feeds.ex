defmodule Portfolio.Content.Feeds do
  @moduledoc """
  Which entries belong to each syndication feed — the Content-owned half of
  the feeds contract (`_PROJECT_DOCS/feeds-spec.md`).

  The four feed names (`:main`, `:case_studies`, `:notes`, `:everything`) are
  the contract shared with the web layer: this module owns membership — the
  `main_feed` type defaults (case studies in, notes out), publication
  filtering (inherited from `Records.list_contents/2`), the strict locale
  promise (an entry without a ja translation appears in no ja feed), and
  cross-type merge-then-cap ordering. The web layer owns titles, routes, and
  Atom serialization, and never re-implements any of this.
  """

  alias Portfolio.Content.Entry.Records
  alias Portfolio.Content.PublicRead.Scope
  alias Portfolio.Content.TranslationRepository

  # newest entries per feed, capped AFTER the cross-type merge
  @entries_per_feed 20

  # Feed name → the type queries it unions. The membership filter encodes the
  # ratified type defaults: a bare note is out of main (only :promoted notes
  # appear); a bare case study is in (only explicit demotion removes it).
  @feeds %{
    main: [{"note", :promoted}, {"case_study", :not_demoted}],
    case_studies: [{"case_study", :all}],
    notes: [{"note", :all}],
    everything: [{"note", :all}, {"case_study", :all}]
  }

  @doc """
  Lists the published entries belonging to `feed`, rendered for `locale`,
  newest first, capped at #{@entries_per_feed}.

  Locale is strict: only entries available in `locale` (canonical or via
  translation) qualify. Translations come merged on the entries, ready for
  locale-aware rendering. Unknown feed names raise.
  """
  @spec list_for_feed(atom(), String.t()) :: [struct()]
  def list_for_feed(feed, locale) do
    # One scope for all type queries: a publication flip mid-listing must not
    # mix entries from two generations in one feed document.
    scope = Scope.current()

    @feeds
    |> Map.fetch!(feed)
    |> Enum.flat_map(fn {type, membership} ->
      Records.list_contents(type,
        scope: scope,
        main_feed: membership,
        available_in: locale,
        sort_by: :published_at,
        sort_order: :desc
      )
    end)
    |> Enum.sort_by(& &1.published_at, {:desc, DateTime})
    |> Enum.take(@entries_per_feed)
    |> merge_translations(locale)
  end

  @doc "The feed names this module accepts — the shared contract with the web layer."
  @spec names() :: [atom()]
  def names, do: Map.keys(@feeds)

  # Same merge shape as EntryAssembler.list_assembled_entries/3, over the
  # already-filtered feed entries.
  defp merge_translations(entries, locale) do
    by_type = Enum.group_by(entries, &translatable_type/1)

    translations =
      Enum.reduce(by_type, %{}, fn {type, typed_entries}, acc ->
        typed_entries
        |> Enum.map(& &1.id)
        |> TranslationRepository.batch_get_translations(type, locale)
        |> Map.merge(acc)
      end)

    Enum.map(entries, fn entry ->
      Map.put(entry, :translations, Map.get(translations, entry.id, %{}))
    end)
  end

  defp translatable_type(%module{}), do: module.translatable_type()
end
