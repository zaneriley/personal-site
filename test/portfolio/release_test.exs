defmodule Portfolio.ReleaseTest do
  use Portfolio.DataCase, async: false

  import Ecto.Query
  import Portfolio.ContentFixtures
  import Portfolio.ContentRepoHelpers

  alias Portfolio.Content
  alias Portfolio.Content.Publishing
  alias Portfolio.Content.Schemas.PublicationGeneration
  alias Portfolio.Content.Schemas.PublicationLedgerEntry
  alias Portfolio.Release
  alias Portfolio.Repo

  describe "pull_repository/0" do
    setup do
      original_repo_url = Application.get_env(:portfolio, :content_repo_url)
      original_base_path = Application.get_env(:portfolio, :content_base_path)
      content_base_path = tmp_dir!("release-clone")

      Application.put_env(:portfolio, :content_repo_url, "/does/not/exist")
      Application.put_env(:portfolio, :content_base_path, content_base_path)

      on_exit(fn ->
        Application.put_env(:portfolio, :content_repo_url, original_repo_url)
        Application.put_env(:portfolio, :content_base_path, original_base_path)
        File.rm_rf!(content_base_path)
      end)

      %{content_base_path: content_base_path}
    end

    test "raises when boot content sync fails and no last-good content exists" do
      assert_raise RuntimeError, ~r/no last-good content exists/, fn ->
        Release.pull_repository()
      end
    end

    test "keeps booting when boot content sync fails but last-good content exists" do
      content_sha = String.duplicate("a", 40)
      {:ok, generation} = Publishing.prepare_generation(content_sha)
      note_fixture(%{}, publication_generation_id: generation.id)

      assert {:ok, _entry} =
               Publishing.record_publication_event(
                 "release-last-good",
                 content_sha,
                 :accepted,
                 generation_id: generation.id
               )

      assert :ok = Release.pull_repository()
      assert Content.content_ready?()

      assert Content.get_publication_state().last_good_content_sha ==
               content_sha
    end

    test "keeps booting when content repo config is invalid but last-good content exists" do
      content_sha = String.duplicate("b", 40)
      {:ok, generation} = Publishing.prepare_generation(content_sha)
      note_fixture(%{}, publication_generation_id: generation.id)

      assert {:ok, _entry} =
               Publishing.record_publication_event(
                 "release-last-good-invalid-config",
                 content_sha,
                 :accepted,
                 generation_id: generation.id
               )

      Application.put_env(:portfolio, :content_repo_url, nil)

      assert :ok = Release.pull_repository()
      assert Content.content_ready?()

      assert Content.get_publication_state().last_good_content_sha ==
               content_sha
    end

    test "dedupes boot sync by resolved content commit", %{
      content_base_path: content_base_path
    } do
      source_repo = tmp_dir!("release-source")
      on_exit(fn -> File.rm_rf!(source_repo) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/release-note/en.md", url: "release-note")
      target_sha = commit!(source_repo, "publish release note")

      Application.put_env(:portfolio, :content_repo_url, source_repo)

      assert :ok = Release.pull_repository()
      assert :ok = Release.pull_repository()
      assert target_sha == rev_parse!(content_base_path, "HEAD")

      accepted_entries =
        PublicationLedgerEntry
        |> where(
          [entry],
          entry.content_sha == ^target_sha and entry.status == "accepted"
        )
        |> Repo.all()

      generation_count =
        PublicationGeneration
        |> where([generation], generation.content_sha == ^target_sha)
        |> Repo.aggregate(:count)

      assert [%PublicationLedgerEntry{} = entry] = accepted_entries
      assert entry.github_delivery_id == "release:#{target_sha}"
      assert generation_count == 1
    end
  end

  describe "read_existing_content/0" do
    setup do
      original_base_path = Application.get_env(:portfolio, :content_base_path)
      content_base_path = tmp_dir!("release-existing-content")

      Application.put_env(:portfolio, :content_base_path, content_base_path)

      on_exit(fn ->
        Application.put_env(:portfolio, :content_base_path, original_base_path)
        File.rm_rf!(content_base_path)
      end)

      %{content_base_path: content_base_path}
    end

    test "publishes the configured content path when the app is already loaded",
         %{content_base_path: content_base_path} do
      write_note!(content_base_path, "notes/release-note/en.md",
        url: "release-note"
      )

      assert :ok = Release.read_existing_content()
      assert Content.content_ready?()

      assert Enum.any?(Content.list("note"), &(&1.url == "release-note"))
    end
  end
end
