defmodule Portfolio.Content.Remote.GitRepoSyncerTest do
  use ExUnit.Case, async: true

  alias Portfolio.Content.Remote.GitRepoSyncer

  import Portfolio.ContentRepoHelpers

  describe "sync_repo/3" do
    test "clones a repository to the target SHA" do
      source_repo = tmp_dir!("sync-source")
      clone_path = tmp_dir!("sync-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/first/en.md", url: "first")
      first_sha = commit!(source_repo, "first note")
      write_note!(source_repo, "notes/second/en.md", url: "second")
      _second_sha = commit!(source_repo, "second note")

      assert {:ok, ^clone_path} =
               GitRepoSyncer.sync_repo(source_repo, clone_path,
                 target_sha: first_sha
               )

      assert File.exists?(Path.join(clone_path, "notes/first/en.md"))
      refute File.exists?(Path.join(clone_path, "notes/second/en.md"))
      assert first_sha == rev_parse!(clone_path, "HEAD")
    end

    test "updates an existing clone and removes untracked files" do
      source_repo = tmp_dir!("sync-existing-source")
      clone_path = tmp_dir!("sync-existing-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/first/en.md", url: "first")
      first_sha = commit!(source_repo, "first note")

      assert {:ok, ^clone_path} =
               GitRepoSyncer.sync_repo(source_repo, clone_path,
                 target_sha: first_sha
               )

      write_file!(clone_path, "scratch.txt", "local scratch")
      write_note!(source_repo, "notes/second/en.md", url: "second")
      second_sha = commit!(source_repo, "second note")

      assert {:ok, ^clone_path} =
               GitRepoSyncer.sync_repo(source_repo, clone_path,
                 target_sha: second_sha
               )

      refute File.exists?(Path.join(clone_path, "scratch.txt"))
      assert File.exists?(Path.join(clone_path, "notes/second/en.md"))
      assert second_sha == rev_parse!(clone_path, "HEAD")
    end

    test "replaces an existing non-git content directory after clone succeeds" do
      source_repo = tmp_dir!("sync-non-git-source")
      clone_path = tmp_dir!("sync-non-git-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/published-note/en.md")
      target_sha = commit!(source_repo, "publish note")
      write_file!(clone_path, "baked-snapshot.txt", "old baked content")

      assert {:ok, ^clone_path} =
               GitRepoSyncer.sync_repo(source_repo, clone_path,
                 target_sha: target_sha
               )

      assert File.dir?(Path.join(clone_path, ".git"))
      assert File.exists?(Path.join(clone_path, "notes/published-note/en.md"))
      refute File.exists?(Path.join(clone_path, "baked-snapshot.txt"))
      assert target_sha == rev_parse!(clone_path, "HEAD")
    end

    test "returns an error for an invalid repository URL" do
      clone_path = tmp_dir!("sync-invalid-clone")
      on_exit(fn -> File.rm_rf!(clone_path) end)

      assert {:error, _reason} =
               GitRepoSyncer.sync_repo("/does/not/exist", clone_path)

      refute File.exists?(Path.join(clone_path, ".git"))
    end
  end
end
