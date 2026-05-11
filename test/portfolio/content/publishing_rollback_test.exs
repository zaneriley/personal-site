defmodule Portfolio.Content.PublishingRollbackTest do
  use Portfolio.DataCase, async: false

  import Portfolio.ContentFixtures

  alias Portfolio.Content
  alias Portfolio.Content.Publishing
  alias Portfolio.Content.PublicationControl.Scope
  alias Portfolio.Content.Schemas.PublicationGeneration
  alias Portfolio.Content.Schemas.PublicationLedgerEntry
  alias Portfolio.Repo

  describe "rollback/3" do
    test "refuses to guess when a content SHA maps to multiple generations" do
      content_sha = String.duplicate("a", 40)
      {:ok, first_generation} = Publishing.prepare_generation(content_sha)
      {:ok, second_generation} = Publishing.prepare_generation(content_sha)

      note_fixture(%{"url" => "ambiguous-first"},
        publication_generation_id: first_generation.id
      )

      note_fixture(%{"url" => "ambiguous-second"},
        publication_generation_id: second_generation.id
      )

      assert {:ok, _first} =
               Publishing.record_publication_event(
                 "ambiguous-delivery-1",
                 content_sha,
                 :accepted,
                 generation_id: first_generation.id
               )

      assert {:ok, _second} =
               Publishing.record_publication_event(
                 "ambiguous-delivery-2",
                 content_sha,
                 :accepted,
                 generation_id: second_generation.id
               )

      ledger_count_before = Repo.aggregate(PublicationLedgerEntry, :count)

      assert {:error, {:ambiguous_content_sha, ^content_sha, generations}} =
               Publishing.rollback(
                 Scope.system(),
                 content_sha,
                 reason: "bad publish"
               )

      generation_ids = Enum.map(generations, & &1.id)

      assert generation_ids == [
               first_generation.id,
               second_generation.id
             ]

      state = Publishing.get_publication_state()

      assert state.live_content_sha == content_sha

      assert state.live_content_publication_generation_id ==
               second_generation.id

      assert Repo.aggregate(PublicationLedgerEntry, :count) ==
               ledger_count_before
    end

    test "rolls back to a known-good generation without rewriting accepted history" do
      first_sha = String.duplicate("1", 40)
      second_sha = String.duplicate("2", 40)
      {:ok, first_generation} = Publishing.prepare_generation(first_sha)
      {:ok, second_generation} = Publishing.prepare_generation(second_sha)

      first_note =
        note_fixture(%{"url" => "rollback-generation-a"},
          publication_generation_id: first_generation.id
        )

      second_note =
        note_fixture(%{"url" => "rollback-generation-b"},
          publication_generation_id: second_generation.id
        )

      assert {:ok, _first} =
               Publishing.record_publication_event(
                 "rollback-delivery-a",
                 first_sha,
                 :accepted,
                 generation_id: first_generation.id
               )

      assert {:ok, _second} =
               Publishing.record_publication_event(
                 "rollback-delivery-b",
                 second_sha,
                 :accepted,
                 generation_id: second_generation.id
               )

      assert {:ok, result} =
               Publishing.rollback(
                 Scope.system(),
                 first_generation.id,
                 reason: "recovery"
               )

      state = Publishing.get_publication_state()
      rollback_entry = Repo.get!(PublicationLedgerEntry, result.ledger_entry_id)

      assert result.status == "rollback"
      assert result.content_sha == first_sha
      assert result.generation_id == first_generation.id
      assert result.previous_generation_id == second_generation.id
      assert rollback_entry.status == "rollback"
      assert rollback_entry.reason == "recovery"

      assert rollback_entry.content_publication_generation_id ==
               first_generation.id

      assert state.live_content_sha == first_sha
      assert state.last_good_content_sha == first_sha
      assert state.last_accepted_content_sha == second_sha
      assert state.live_content_publication_generation_id == first_generation.id

      assert %PublicationGeneration{status: "live"} =
               Repo.get!(PublicationGeneration, first_generation.id)

      assert %PublicationGeneration{status: "superseded"} =
               Repo.get!(PublicationGeneration, second_generation.id)

      live_urls =
        "note"
        |> Content.list()
        |> Enum.map(& &1.url)

      assert live_urls == [first_note.url]
      refute Enum.member?(live_urls, second_note.url)
    end
  end
end
