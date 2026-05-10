defmodule Portfolio.Content.Remote.RemoteUpdateTriggerTest do
  use Portfolio.DataCase, async: true

  import Mox
  alias Portfolio.Content
  alias Portfolio.Content.Remote.GitHubStatusClient
  alias Portfolio.Content.Remote.RemoteUpdateTrigger
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Repo

  import Portfolio.ContentRepoHelpers

  setup :verify_on_exit!

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
               "notes/published-note/en.md"
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

      write_note!(source_repo, "notes/surviving-note/en.md",
        url: "surviving-note"
      )

      first_sha = commit!(source_repo, "publish note")

      assert {:ok, _result} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{
                   upsert: [
                     "notes/published-note/en.md",
                     "notes/surviving-note/en.md"
                   ],
                   delete: []
                 },
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

      assert result.promoted == [
               Path.expand("notes/surviving-note/en.md", clone_path)
             ]

      refute Enum.any?(Content.list("note"), &(&1.url == "published-note"))
      assert Enum.any?(Content.list("note"), &(&1.url == "surviving-note"))
      assert second_sha == rev_parse!(clone_path, "HEAD")

      assert %{status: "accepted", removed_paths: removed_paths} =
               Content.get_publication_verdict(second_sha)

      assert removed_paths == [
               "notes/published-note/en.md"
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

      assert {:error, reason} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{
                   upsert: ["notes/good-note/en.md", "notes/bad-note/en.md"],
                   delete: []
                 },
                 target_sha: target_sha,
                 github_delivery_id: "delivery-first-invalid-note"
               )

      assert reason =~ "notes/bad-note/en.md:"

      assert reason =~
               "invalid markdown format: expected YAML frontmatter delimited by ---"

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

      assert {:error, reason} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/published-note/en.md"], delete: []},
                 target_sha: target_sha,
                 github_delivery_id: "delivery-invalid-note"
               )

      assert reason =~ "notes/published-note/en.md:"

      assert reason =~
               "invalid markdown format: expected YAML frontmatter delimited by ---"

      assert %{status: "rejected", reason: ^reason} =
               verdict = Content.get_publication_verdict(target_sha)

      assert [
               %{
                 "path" => invalid_path,
                 "reason" => reason
               }
             ] = verdict.structured_errors["errors"]

      assert invalid_path == "notes/published-note/en.md"

      assert is_binary(reason)

      assert %{
               live_content_sha: ^accepted_sha,
               last_good_content_sha: ^accepted_sha
             } =
               Content.get_publication_state()
    end

    test "rejected mixed updates keep serving old live rows" do
      source_repo = tmp_dir!("remote-partial-invalid-content-source")
      clone_path = tmp_dir!("remote-partial-invalid-content-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)

      write_note!(source_repo, "notes/published-note/en.md",
        title: "Old Live Title"
      )

      accepted_sha = commit!(source_repo, "publish valid note")

      assert {:ok, _result} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/published-note/en.md"], delete: []},
                 target_sha: accepted_sha,
                 github_delivery_id: "delivery-partial-valid-before-invalid"
               )

      assert %Note{id: live_note_id, title: "Old Live Title"} =
               Content.get!("note", "published-note")

      write_note!(source_repo, "notes/published-note/en.md",
        title: "New Hidden Title"
      )

      write_file!(
        source_repo,
        "notes/bad-note/en.md",
        """
        ---
        url: "bad-note"
        introduction: "Intro"
        published_at: "2024-07-27T14:30:00Z"
        is_draft: false
        ---

        # Missing Title
        """
      )

      rejected_sha = commit!(source_repo, "publish mixed invalid note")

      assert {:error, reason} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{
                   upsert: [
                     "notes/published-note/en.md",
                     "notes/bad-note/en.md"
                   ],
                   delete: []
                 },
                 target_sha: rejected_sha,
                 github_delivery_id: "delivery-partial-invalid-note"
               )

      assert reason =~ "notes/bad-note/en.md: title: can't be blank"

      assert %Note{id: ^live_note_id, title: "Old Live Title"} =
               Content.get!("note", "published-note")

      assert %{
               live_content_sha: ^accepted_sha,
               last_good_content_sha: ^accepted_sha,
               last_rejected_content_sha: ^rejected_sha
             } = Content.get_publication_state()
    end

    test "rejects mixed delete and add updates that do not preserve deleted URLs" do
      source_repo = tmp_dir!("remote-rename-without-alias-source")
      clone_path = tmp_dir!("remote-rename-without-alias-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/old-note/en.md", url: "old-note")
      accepted_sha = commit!(source_repo, "publish old note")

      assert {:ok, _result} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/old-note/en.md"], delete: []},
                 target_sha: accepted_sha,
                 github_delivery_id: "delivery-rename-old-note"
               )

      delete_file!(source_repo, "notes/old-note/en.md")
      write_note!(source_repo, "notes/new-note/en.md", url: "new-note")
      rejected_sha = commit!(source_repo, "rename without alias")

      assert {:error, reason} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{
                   upsert: ["notes/new-note/en.md"],
                   delete: ["notes/old-note/en.md"]
                 },
                 target_sha: rejected_sha,
                 github_delivery_id: "delivery-rename-without-alias"
               )

      assert reason =~ "notes/old-note/en.md:"

      assert reason =~
               "deleted URL old-note needs an alias on new content or a deletion-only commit"

      assert %Note{url: "old-note"} = Content.get!("note", "old-note")

      assert_raise Ecto.NoResultsError, fn ->
        Content.get!("note", "new-note")
      end

      assert %{
               live_content_sha: ^accepted_sha,
               last_rejected_content_sha: ^rejected_sha
             } = Content.get_publication_state()
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

    test "replays an existing verdict status for duplicate GitHub deliveries" do
      source_repo = tmp_dir!("remote-duplicate-status-source")
      clone_path = tmp_dir!("remote-duplicate-status-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/published-note/en.md")
      first_sha = commit!(source_repo, "publish first note")

      assert {:ok, _result} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/published-note/en.md"], delete: []},
                 target_sha: first_sha,
                 github_delivery_id: "delivery-duplicate-status"
               )

      write_note!(source_repo, "notes/published-note/en.md",
        title: "Second Title"
      )

      second_sha = commit!(source_repo, "publish second note")

      expect(GitHubStatusClient.Mock, :create_status, fn
        "zaneriley", "personal-site-content", ^first_sha, payload, _opts ->
          assert payload.state == "success"
          assert payload.description == "Content accepted and live"
          assert payload.target_url =~ "/ops/content/publications/"

          :ok
      end)

      assert {:ok, %{duplicate?: true}} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/published-note/en.md"], delete: []},
                 target_sha: second_sha,
                 github_delivery_id: "delivery-duplicate-status",
                 github_token: "token",
                 github_status_client: GitHubStatusClient.Mock,
                 github_status_owner: "zaneriley",
                 github_status_repo: "personal-site-content"
               )

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
