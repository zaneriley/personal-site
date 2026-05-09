defmodule Portfolio.Content.PublishingTest do
  use Portfolio.DataCase, async: true

  import Portfolio.ContentFixtures

  alias Portfolio.Content.Publishing
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Content.Schemas.PublicationLedgerEntry
  alias Portfolio.Repo

  describe "record_publication_event/4" do
    test "appends repeated content SHAs with distinct GitHub delivery IDs" do
      content_sha = String.duplicate("a", 40)
      {:ok, first_generation} = Publishing.prepare_generation(content_sha)
      {:ok, second_generation} = Publishing.prepare_generation(content_sha)

      assert {:ok, first} =
               Publishing.record_publication_event(
                 "delivery-1",
                 content_sha,
                 :accepted,
                 generation_id: first_generation.id
               )

      assert {:ok, second} =
               Publishing.record_publication_event(
                 "delivery-2",
                 content_sha,
                 :accepted,
                 generation_id: second_generation.id
               )

      assert first.id != second.id
      assert first.content_sha == second.content_sha

      assert %PublicationLedgerEntry{} =
               Publishing.latest_publication_event(content_sha)
    end

    test "dedupes repeated GitHub delivery IDs without changing live state" do
      first_sha = String.duplicate("a", 40)
      second_sha = String.duplicate("b", 40)
      {:ok, generation} = Publishing.prepare_generation(first_sha)

      assert {:ok, accepted} =
               Publishing.record_publication_event(
                 "delivery-1",
                 first_sha,
                 :accepted,
                 generation_id: generation.id
               )

      assert {:ok, duplicate} =
               Publishing.record_publication_event(
                 "delivery-1",
                 second_sha,
                 :rejected,
                 reason: "should not overwrite"
               )

      state = Publishing.get_publication_state()

      assert duplicate.id == accepted.id
      assert state.live_content_sha == first_sha
      assert state.last_good_content_sha == first_sha
      refute state.last_rejected_content_sha
    end

    test "accepted events require an explicit generation" do
      assert {:error, changeset} =
               Publishing.record_publication_event(
                 "delivery-missing-generation",
                 String.duplicate("a", 40),
                 :accepted
               )

      assert %{
               content_publication_generation_id: [
                 "is required for accepted publication events"
               ]
             } = errors_on(changeset)
    end

    test "rejected and ignored events preserve live and last-good content" do
      live_sha = String.duplicate("a", 40)
      rejected_sha = String.duplicate("b", 40)
      ignored_sha = String.duplicate("c", 40)
      {:ok, generation} = Publishing.prepare_generation(live_sha)

      assert {:ok, _accepted} =
               Publishing.record_publication_event(
                 "accepted-delivery",
                 live_sha,
                 :accepted,
                 generation_id: generation.id
               )

      assert {:ok, _rejected} =
               Publishing.record_publication_event(
                 "rejected-delivery",
                 rejected_sha,
                 :rejected,
                 reason: "Content promotion failed"
               )

      assert {:ok, _ignored} =
               Publishing.record_publication_event(
                 "ignored-delivery",
                 ignored_sha,
                 :ignored,
                 reason: "No relevant content changes"
               )

      state = Publishing.get_publication_state()

      assert state.live_content_sha == live_sha
      assert state.last_good_content_sha == live_sha
      assert state.last_rejected_content_sha == rejected_sha
      assert state.last_rejected_reason == "Content promotion failed"
      assert state.last_ignored_content_sha == ignored_sha
      assert state.last_ignored_reason == "No relevant content changes"
    end

    test "operator status exposes rejected, ignored, and failure details" do
      live_sha = String.duplicate("a", 40)
      rejected_sha = String.duplicate("b", 40)
      ignored_sha = String.duplicate("c", 40)
      {:ok, generation} = Publishing.prepare_generation(live_sha)

      assert {:ok, _accepted} =
               Publishing.record_publication_event(
                 "status-accepted-delivery",
                 live_sha,
                 :accepted,
                 generation_id: generation.id
               )

      assert {:ok, _rejected} =
               Publishing.record_publication_event(
                 "status-rejected-delivery",
                 rejected_sha,
                 :rejected,
                 reason: "Content promotion failed"
               )

      failed_status = Publishing.status()

      assert failed_status.last_rejected == %{
               content_sha: rejected_sha,
               reason: "Content promotion failed"
             }

      assert failed_status.last_failure_reason == "Content promotion failed"

      assert {:ok, _ignored} =
               Publishing.record_publication_event(
                 "status-ignored-delivery",
                 ignored_sha,
                 :ignored,
                 reason: "No relevant content changes"
               )

      idle_status = Publishing.status()
      status_text = Publishing.status_text()

      assert idle_status.last_ignored == %{
               content_sha: ignored_sha,
               reason: "No relevant content changes"
             }

      assert idle_status.last_failure_reason == nil
      assert status_text =~ "Last rejected SHA: #{rejected_sha}"
      assert status_text =~ "Last ignored SHA: #{ignored_sha}"
      assert status_text =~ "Last failure reason: none"
    end
  end

  describe "content_ready?/0" do
    test "requires a live generation with published content rows" do
      content_sha = String.duplicate("d", 40)
      {:ok, generation} = Publishing.prepare_generation(content_sha)

      assert {:ok, _entry} =
               Publishing.record_publication_event(
                 "ready-without-content",
                 content_sha,
                 :accepted,
                 generation_id: generation.id
               )

      refute Publishing.content_ready?()

      note_fixture(%{}, publication_generation_id: generation.id)

      assert Publishing.content_ready?()
    end

    test "returns false when state points at missing live content" do
      content_sha = String.duplicate("e", 40)
      {:ok, generation} = Publishing.prepare_generation(content_sha)

      note = note_fixture(%{}, publication_generation_id: generation.id)

      assert {:ok, _entry} =
               Publishing.record_publication_event(
                 "ready-then-missing",
                 content_sha,
                 :accepted,
                 generation_id: generation.id
               )

      assert Publishing.content_ready?()

      note_id = note.id
      Repo.delete_all(from note in Note, where: note.id == ^note_id)

      refute Publishing.content_ready?()
    end
  end
end
