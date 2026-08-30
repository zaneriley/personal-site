defmodule Portfolio.Content.FeedsTest do
  use Portfolio.DataCase

  import Portfolio.ContentFixtures

  alias Portfolio.Content

  describe "list_for_feed/2 — main-feed membership" do
    test "a promoted note appears in the main feed; an unpromoted note does not" do
      promoted = note_fixture(%{"main_feed" => true})
      _unpromoted = note_fixture()

      ids = ids_for(:main, "en")

      assert promoted.id in ids
      assert length(ids) == 1
    end

    test "a case study is in the main feed by default; demoting removes it" do
      default_in = case_study_fixture()
      demoted = case_study_fixture(%{"main_feed" => false})

      ids = ids_for(:main, "en")

      assert default_in.id in ids
      refute demoted.id in ids
    end
  end

  describe "list_for_feed/2 — publication safety" do
    test "drafts and unpublished entries appear in no feed" do
      draft = note_fixture(%{"is_draft" => true, "main_feed" => true})
      unpublished = note_fixture(%{"published_at" => nil, "main_feed" => true})

      for feed <- [:main, :notes, :everything] do
        ids = ids_for(feed, "en")
        refute draft.id in ids
        refute unpublished.id in ids
      end
    end
  end

  describe "list_for_feed/2 — the locale promise" do
    test "an entry without a ja translation appears in no ja feed" do
      untranslated = note_fixture(%{}, skip_translations: true)
      translated = note_fixture()

      ja_ids = ids_for(:notes, "ja")

      refute untranslated.id in ja_ids
      assert translated.id in ja_ids

      # both remain visible to en subscribers
      en_ids = ids_for(:notes, "en")
      assert untranslated.id in en_ids
      assert translated.id in en_ids
    end
  end

  describe "list_for_feed/2 — the everything feed" do
    test "merges both types by recency and caps after the merge" do
      # 12 notes and 12 case studies with strictly interleaved recency
      for i <- 1..12 do
        note_fixture(%{"published_at" => at_minute(2 * i)})
        case_study_fixture(%{"published_at" => at_minute(2 * i + 1)})
      end

      entries = Content.list_for_feed(:everything, "en")

      assert length(entries) == 20

      dates = Enum.map(entries, & &1.published_at)
      assert dates == Enum.sort(dates, {:desc, DateTime})

      # capping after the merge keeps BOTH types in the newest 20 —
      # a per-type cap would have taken 20 of one kind
      types = entries |> Enum.map(& &1.__struct__) |> Enum.uniq()
      assert length(types) == 2
    end
  end

  describe "list_for_feed/2 — unknown feeds" do
    test "an unknown feed name is an error, not an empty feed" do
      assert_raise KeyError, fn -> Content.list_for_feed(:secrets, "en") end
    end
  end

  defp ids_for(feed, locale) do
    feed |> Content.list_for_feed(locale) |> Enum.map(& &1.id)
  end

  defp at_minute(m) do
    DateTime.add(~U[2024-01-01 00:00:00Z], m * 60, :second)
  end
end
