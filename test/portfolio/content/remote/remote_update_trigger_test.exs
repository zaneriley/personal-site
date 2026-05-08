defmodule Portfolio.Content.Remote.RemoteUpdateTriggerTest do
  use Portfolio.DataCase, async: true

  alias Portfolio.Content.Remote.RemoteUpdateTrigger
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Repo

  import Portfolio.ContentRepoHelpers

  describe "start_link/1" do
    test "starts the Agent process" do
      assert {:ok, pid} = RemoteUpdateTrigger.start_link([])
      assert Process.alive?(pid)
      assert Agent.get(RemoteUpdateTrigger, fn state -> state end) == %{}
    end
  end

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
                 target_sha: target_sha
               )

      assert result.promoted == [
               Path.expand("notes/published-note/en.md", clone_path)
             ]

      assert %Note{title: "Published Note"} =
               Repo.get_by(Note, url: "published-note")

      assert target_sha == rev_parse!(clone_path, "HEAD")
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
                 target_sha: first_sha
               )

      assert %Note{} = Repo.get_by(Note, url: "published-note")

      delete_file!(source_repo, "notes/published-note/en.md")
      second_sha = commit!(source_repo, "remove note")

      assert {:ok, result} =
               RemoteUpdateTrigger.trigger_update(source_repo,
                 content_base_path: clone_path,
                 changes: %{upsert: [], delete: ["notes/published-note/en.md"]},
                 target_sha: second_sha
               )

      assert result.removed == [
               Path.expand("notes/published-note/en.md", clone_path)
             ]

      refute Repo.get_by(Note, url: "published-note")
      assert second_sha == rev_parse!(clone_path, "HEAD")
    end

    test "returns an error for an invalid repository URL" do
      clone_path = tmp_dir!("remote-invalid-clone")
      on_exit(fn -> File.rm_rf!(clone_path) end)

      assert {:error, "Repository sync failed"} =
               RemoteUpdateTrigger.trigger_update("/does/not/exist",
                 content_base_path: clone_path,
                 changes: %{upsert: ["notes/published-note/en.md"], delete: []},
                 target_sha: String.duplicate("a", 40)
               )
    end
  end
end
