defmodule Portfolio.Content.FileManagement.GitRepoSyncerTest do
  use ExUnit.Case
  alias Portfolio.Content.Remote.GitRepoSyncer
  require Logger

  @invalid_repo_url "https://invalid-url.com/repo.git"

  # The tests here are a bit brittle because of how they're expecting the folder to be cloned

  # Add this helper function at the top of the module
  defp typeof(term) do
    cond do
      is_binary(term) -> "binary"
      is_list(term) -> "list"
      is_atom(term) -> "atom"
      is_integer(term) -> "integer"
      true -> "other"
    end
  end

  setup do
    valid_repo_url = Application.get_env(:portfolio, :content_repo_url)

    local_path =
      Application.get_env(:portfolio, :content_base_path, "priv/content")

    # Add these logging statements at the beginning of the setup block
    Logger.warn(
      "Setup - valid_repo_url: #{inspect(valid_repo_url)}, type: #{typeof(valid_repo_url)}"
    )

    Logger.warn(
      "Setup - local_path: #{inspect(local_path)}, type: #{typeof(local_path)}"
    )

    unless File.exists?(local_path) do
      System.cmd("git", ["clone", valid_repo_url, local_path],
        env: %{"GIT_TERMINAL_PROMPT" => "0"},
        into: IO.stream(:stdio, :line)
      )
    end

    {:ok, valid_repo_url: valid_repo_url, local_path: local_path}
  end

  test "clones repository successfully", %{
    valid_repo_url: valid_repo_url,
    local_path: local_path
  } do
    Logger.warn(
      "Test clone - valid_repo_url: #{inspect(valid_repo_url)}, type: #{typeof(valid_repo_url)}"
    )

    Logger.warn(
      "Test clone - local_path: #{inspect(local_path)}, type: #{typeof(local_path)}"
    )

    assert {:ok, _repo} = GitRepoSyncer.sync_repo(valid_repo_url, local_path)
    assert File.exists?(local_path)
    File.rm_rf!(local_path)
  end

  test "handles invalid repository URL", %{local_path: local_path} do
    # Add these logging statements at the beginning of the test
    Logger.warn(
      "Test invalid - invalid_repo_url: #{inspect(@invalid_repo_url)}, type: #{typeof(@invalid_repo_url)}"
    )

    Logger.warn(
      "Test invalid - local_path: #{inspect(local_path)}, type: #{typeof(local_path)}"
    )

    File.rm_rf!(local_path)

    assert {:error, _reason} =
             GitRepoSyncer.sync_repo(@invalid_repo_url, local_path)

    refute File.exists?(local_path)
  end

  test "handles existing directory", %{
    valid_repo_url: valid_repo_url,
    local_path: local_path
  } do
    # Add these logging statements at the beginning of the test
    Logger.warn(
      "Test existing - valid_repo_url: #{inspect(valid_repo_url)}, type: #{typeof(valid_repo_url)}"
    )

    Logger.warn(
      "Test existing - local_path: #{inspect(local_path)}, type: #{typeof(local_path)}"
    )

    assert {:ok, _repo} = GitRepoSyncer.sync_repo(valid_repo_url, local_path)
    assert File.exists?(local_path)
  end

  # test "handles network issues" do
  #   # Simulate network issue by using an invalid URL
  #   assert {:error, _reason} =
  #            GitRepoSyncer.sync_repo(@invalid_repo_url, local_path)

  #   refute File.exists?(local_path)
  # end

  # test "clones to non-existent directory" do
  #   non_existent_path = "priv/non_existent_content"

  #   assert {:ok, _repo} =
  #            GitRepoSyncer.sync_repo(valid_repo_url, non_existent_path)

  #   assert File.exists?(non_existent_path)
  # end

  # test "clones with authentication" do
  #   # Assuming we have a private repository that requires authentication
  #   private_repo_url = "https://github.com/username/private-repo.git"
  #   auth_options = [username: "username", password: "password"]

  #   assert {:ok, _repo} =
  #            GitRepoSyncer.sync_repo(private_repo_url, local_path, auth_options)

  #   assert File.exists?(local_path)
  # end
end
