defmodule Portfolio.Content.Remote.RemoteUpdateTriggerTest do
  use Portfolio.DataCase, async: true

  alias Portfolio.Content
  alias Portfolio.Content.Remote.RemoteUpdateTrigger
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Repo

  import Portfolio.ContentRepoHelpers

  describe "trigger_update/2" do
    test "syncs the target SHA and promotes changed content" do
      source_repo = tmp_dir!("remote-source")
      clone_path = tmp_dir!("remote-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/published-note/en.md")
      target_sha = commit!(source_repo, "publish note")

      assert {:ok, result} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/published-note/en.md"], delete: []},
                 target_sha: target_sha,
                 github_delivery_id: "delivery-publish-note"
               )

      assert result.promoted == [
               Path.expand("notes/published-note/en.md", clone_path)
             ]

      assert %Note{title: "Published Note"} =
               Repo.get_by(Note, url: "published-note")

      assert target_sha == rev_parse!(clone_path, "HEAD")

      assert %{status: "accepted", promoted_paths: promoted_paths} =
               Content.get_publication_verdict(target_sha)

      assert promoted_paths == [
               Path.expand("notes/published-note/en.md", clone_path)
             ]

      assert %{
               live_content_sha: ^target_sha,
               last_good_content_sha: ^target_sha
             } =
               Content.get_publication_state()
    end

    test "removes content when the target SHA deletes markdown" do
      source_repo = tmp_dir!("remote-delete-source")
      clone_path = tmp_dir!("remote-delete-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/published-note/en.md")
      first_sha = commit!(source_repo, "publish note")

      assert {:ok, _result} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/published-note/en.md"], delete: []},
                 target_sha: first_sha,
                 github_delivery_id: "delivery-delete-first"
               )

      assert %Note{} = Repo.get_by(Note, url: "published-note")

      delete_file!(source_repo, "notes/published-note/en.md")
      second_sha = commit!(source_repo, "remove note")

      assert {:ok, result} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: [], delete: ["notes/published-note/en.md"]},
                 target_sha: second_sha,
                 github_delivery_id: "delivery-delete-second"
               )

      assert result.promoted == []

      refute Enum.any?(Content.list("note"), &(&1.url == "published-note"))
      assert second_sha == rev_parse!(clone_path, "HEAD")

      assert %{status: "accepted", removed_paths: removed_paths} =
               Content.get_publication_verdict(second_sha)

      assert removed_paths == [
               Path.expand("notes/published-note/en.md", clone_path)
             ]

      assert %{
               live_content_sha: ^second_sha,
               last_good_content_sha: ^second_sha
             } =
               Content.get_publication_state()
    end

    test "failed first publish does not expose prepared generation rows" do
      source_repo = tmp_dir!("remote-first-invalid-content-source")
      clone_path = tmp_dir!("remote-first-invalid-content-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/good-note/en.md", url: "good-note")
      write_invalid_note!(source_repo, "notes/bad-note/en.md")
      target_sha = commit!(source_repo, "publish mixed invalid content")

      assert {:error, "Content promotion failed"} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{
                   upsert: ["notes/good-note/en.md", "notes/bad-note/en.md"],
                   delete: []
                 },
                 target_sha: target_sha,
                 github_delivery_id: "delivery-first-invalid-note"
               )

      assert %{status: "rejected"} = Content.get_publication_verdict(target_sha)
      assert Content.list("note") == []
      refute Content.content_ready?()
    end

    test "records a rejected verdict without changing live content when promotion fails" do
      source_repo = tmp_dir!("remote-invalid-content-source")
      clone_path = tmp_dir!("remote-invalid-content-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/published-note/en.md")
      accepted_sha = commit!(source_repo, "publish valid note")

      assert {:ok, _result} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/published-note/en.md"], delete: []},
                 target_sha: accepted_sha,
                 github_delivery_id: "delivery-valid-before-invalid"
               )

      write_invalid_note!(source_repo, "notes/published-note/en.md")
      target_sha = commit!(source_repo, "publish invalid note")

      assert {:error, "Content promotion failed"} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/published-note/en.md"], delete: []},
                 target_sha: target_sha,
                 github_delivery_id: "delivery-invalid-note"
               )

      assert %{status: "rejected", reason: "Content promotion failed"} =
               verdict = Content.get_publication_verdict(target_sha)

      assert [
               %{
                 "path" => invalid_path,
                 "reason" => reason
               }
             ] = verdict.structured_errors["errors"]

      assert invalid_path ==
               Path.expand("notes/published-note/en.md", clone_path)

      assert is_binary(reason)

      assert %{
               live_content_sha: ^accepted_sha,
               last_good_content_sha: ^accepted_sha
             } =
               Content.get_publication_state()
    end

    test "does not sync or promote duplicate GitHub deliveries" do
      source_repo = tmp_dir!("remote-duplicate-source")
      clone_path = tmp_dir!("remote-duplicate-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)

      write_note!(source_repo, "notes/published-note/en.md",
        title: "First Title"
      )

      first_sha = commit!(source_repo, "publish first note")

      assert {:ok, _result} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/published-note/en.md"], delete: []},
                 target_sha: first_sha,
                 github_delivery_id: "delivery-duplicate"
               )

      write_note!(source_repo, "notes/published-note/en.md",
        title: "Second Title"
      )

      second_sha = commit!(source_repo, "publish second note")

      assert {:ok, %{duplicate?: true}} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/published-note/en.md"], delete: []},
                 target_sha: second_sha,
                 github_delivery_id: "delivery-duplicate"
               )

      assert %Note{title: "First Title"} =
               Repo.get_by(Note, url: "published-note")

      assert first_sha == rev_parse!(clone_path, "HEAD")
      assert Content.get_publication_state().live_content_sha == first_sha
    end

    test "returns an error for an invalid repository URL" do
      clone_path = tmp_dir!("remote-invalid-clone")
      target_sha = String.duplicate("a", 40)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      assert {:error, "Repository sync failed"} =
               RemoteUpdateTrigger.trigger_update("/does/not/exist",
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/published-note/en.md"], delete: []},
                 target_sha: target_sha,
                 github_delivery_id: "delivery-invalid-repo"
               )

      assert %{status: "rejected", reason: reason} =
               Content.get_publication_verdict(target_sha)

      assert String.starts_with?(reason, "Repository sync failed:")
    end
  end
end
