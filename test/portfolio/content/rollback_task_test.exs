defmodule Mix.Tasks.Portfolio.Content.RollbackTest do
  use Portfolio.DataCase, async: false

  import Portfolio.ContentFixtures

  alias Mix.Tasks.Portfolio.Content.Rollback
  alias Portfolio.Content.Publishing
  alias Portfolio.Content.Schemas.PublicationLedgerEntry
  alias Portfolio.Repo

  setup do
    previous_shell = Mix.shell()

    Mix.shell(Mix.Shell.Process)
    Mix.Task.reenable("app.start")

    on_exit(fn ->
      Mix.shell(previous_shell)
      Mix.Task.reenable("app.start")
    end)

    :ok
  end

  describe "run/1" do
    test "prints a successful rollback result" do
      first_sha = String.duplicate("1", 40)
      second_sha = String.duplicate("2", 40)
      {:ok, first_generation} = Publishing.prepare_generation(first_sha)
      {:ok, second_generation} = Publishing.prepare_generation(second_sha)

      note_fixture(%{"url" => "rollback-task-a"},
        publication_generation_id: first_generation.id
      )

      note_fixture(%{"url" => "rollback-task-b"},
        publication_generation_id: second_generation.id
      )

      assert {:ok, _entry} =
               Publishing.record_publication_event(
                 "rollback-task-delivery-a",
                 first_sha,
                 :accepted,
                 generation_id: first_generation.id
               )

      assert {:ok, _entry} =
               Publishing.record_publication_event(
                 "rollback-task-delivery-b",
                 second_sha,
                 :accepted,
                 generation_id: second_generation.id
               )

      assert :ok =
               Rollback.run([
                 first_generation.id,
                 "--reason",
                 "operator recovery"
               ])

      assert_receive {:mix_shell, :info, [text_output]}

      assert text_output =~
               "Rolled back content to generation #{first_generation.id}"

      assert text_output =~ "Content SHA: #{first_sha}"
      assert text_output =~ "Previous live generation: #{second_generation.id}"
      assert text_output =~ "Reason: operator recovery"
    end

    test "prints stable JSON for ambiguous content SHAs" do
      content_sha = String.duplicate("a", 40)
      {:ok, first_generation} = Publishing.prepare_generation(content_sha)
      {:ok, second_generation} = Publishing.prepare_generation(content_sha)

      note_fixture(%{"url" => "rollback-task-ambiguous-a"},
        publication_generation_id: first_generation.id
      )

      note_fixture(%{"url" => "rollback-task-ambiguous-b"},
        publication_generation_id: second_generation.id
      )

      assert {:ok, _entry} =
               Publishing.record_publication_event(
                 "rollback-task-ambiguous-a",
                 content_sha,
                 :accepted,
                 generation_id: first_generation.id
               )

      assert {:ok, _entry} =
               Publishing.record_publication_event(
                 "rollback-task-ambiguous-b",
                 content_sha,
                 :accepted,
                 generation_id: second_generation.id
               )

      ledger_count_before = Repo.aggregate(PublicationLedgerEntry, :count)

      catch_exit(
        Rollback.run([
          "--json",
          content_sha,
          "--reason",
          "bad publish"
        ])
      )

      assert_receive {:mix_shell, :info, [json_output]}

      assert %{
               "status" => "error",
               "reason" => "ambiguous_content_sha",
               "content_sha" => ^content_sha,
               "matching_generation_ids" => generation_ids
             } = Jason.decode!(json_output)

      assert generation_ids == [first_generation.id, second_generation.id]

      assert Repo.aggregate(PublicationLedgerEntry, :count) ==
               ledger_count_before
    end
  end
end
