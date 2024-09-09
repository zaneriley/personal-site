defmodule Portfolio.Content.Remote.RemoteUpdateTriggerTest do
  use ExUnit.Case
  alias Portfolio.Content.Remote.RemoteUpdateTrigger

  @valid_repo_url Application.compile_env(
                    :portfolio,
                    :content_repo_url
                  )
  @invalid_repo_url "https://github.com/nonexistent/repo.git"
  @local_path Application.compile_env(:portfolio, :content_base_path)

  setup do
    # Clean up the local path before each test
    File.rm_rf!(@local_path)
    :ok
  end

  test "start_link starts the Agent process" do
    assert {:ok, pid} = RemoteUpdateTrigger.start_link([])
    assert Process.alive?(pid)
    assert Agent.get(RemoteUpdateTrigger, fn state -> state end) == %{}
  end

  test "trigger_update with valid repository URL" do
    assert {:ok, :updated} = RemoteUpdateTrigger.trigger_update(@valid_repo_url)
    assert File.dir?(@local_path)
  end

  test "trigger_update with invalid repository URL" do
    assert {:error, "Repository sync failed"} =
             RemoteUpdateTrigger.trigger_update(@invalid_repo_url)

    refute File.dir?(@local_path)
  end

  test "trigger_update with non-existent repository (new clone)" do
    assert {:ok, :updated} = RemoteUpdateTrigger.trigger_update(@valid_repo_url)
    assert File.dir?(@local_path)
    assert File.dir?(Path.join(@local_path, ".git"))
  end

  test "trigger_update with existing repository (pull updates)" do
    # First, clone the repository
    assert {:ok, :updated} = RemoteUpdateTrigger.trigger_update(@valid_repo_url)
    test_file_path = Path.join(@local_path, "test_file.txt")
    File.write!(test_file_path, "test content")

    # Trigger update again
    assert {:ok, :updated} = RemoteUpdateTrigger.trigger_update(@valid_repo_url)
    # Check if file exists and log result
    file_exists = File.exists?(test_file_path)
    # Original assertion
    refute file_exists,
           "EXISTING REPO TEST: Expected test_file.txt to be removed, but it still exists"
  end

  test "trigger_update with no changes in the repository" do
    # First, clone the repository
    assert {:ok, :updated} = RemoteUpdateTrigger.trigger_update(@valid_repo_url)

    # Immediately trigger update again
    assert {:ok, :updated} = RemoteUpdateTrigger.trigger_update(@valid_repo_url)
  end
end
