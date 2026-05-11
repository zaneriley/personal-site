defmodule Portfolio.Content.Remote.GitRepoSyncerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import Mox
  import Portfolio.ContentRepoHelpers

  alias Portfolio.Content.Remote.GitCommand
  alias Portfolio.Content.Remote.GitRepoSyncer

  setup :verify_on_exit!
  setup :set_mox_from_context

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

    test "injects HTTPS token auth ephemerally and redacts failed git output" do
      token = "BOGUS_TOKEN_123"
      repo_url = "https://github.com/zaneriley/private-repo.git"
      clone_path = tmp_dir!("sync-private-clone")
      on_exit(fn -> File.rm_rf!(clone_path) end)

      expect(GitCommand.Mock, :run, fn
        "git", ["clone", "--verbose", ^repo_url, temp_path], opts ->
          env = Keyword.fetch!(opts, :env)

          joined_args =
            Enum.join(["clone", "--verbose", repo_url, temp_path], " ")

          assert {"GIT_ASKPASS", "/tmp/content-git-askpass"} in env
          assert {"CONTENT_REPO_GIT_USERNAME", "x-access-token"} in env
          assert {"CONTENT_REPO_HTTPS_TOKEN", token} in env
          refute joined_args =~ token

          {"fatal: authentication failed for #{token}", 128}
      end)

      assert {:error, reason} =
               GitRepoSyncer.sync_repo(repo_url, clone_path,
                 auth: [
                   askpass_path: "/tmp/content-git-askpass",
                   https_token: token
                 ],
                 git_command: GitCommand.Mock
               )

      refute reason =~ token
      refute File.exists?(Path.join(clone_path, ".git"))
    end

    test "keeps credentials out of persisted git config" do
      token = "BOGUS_TOKEN_123"
      source_repo = tmp_dir!("sync-clean-config-source")
      clone_path = tmp_dir!("sync-clean-config-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/first/en.md", url: "first")
      target_sha = commit!(source_repo, "first note")

      assert {:ok, ^clone_path} =
               GitRepoSyncer.sync_repo(source_repo, clone_path,
                 auth: [
                   askpass_path: "/tmp/content-git-askpass",
                   https_token: token
                 ],
                 target_sha: target_sha
               )

      git_config = File.read!(Path.join(clone_path, ".git/config"))

      refute git_config =~ token
      assert git_config =~ "url = #{source_repo}"
    end

    test "rejects content repo URLs with embedded credentials without leaking them" do
      token = "BOGUS_TOKEN_123"
      clone_path = tmp_dir!("sync-embedded-token-clone")
      repo_url = "https://#{token}@github.com/zaneriley/private-repo.git"
      on_exit(fn -> File.rm_rf!(clone_path) end)

      log =
        capture_log(fn ->
          assert {:error, reason} =
                   GitRepoSyncer.sync_repo(repo_url, clone_path)

          refute reason =~ token
        end)

      refute log =~ token
      refute File.exists?(Path.join(clone_path, ".git"))
    end
  end
end
