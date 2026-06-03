defmodule Portfolio.Content.FileManagement.WatcherTest do
  use Portfolio.DataCase

  alias Portfolio.Content.FileManagement.Watcher
  alias Portfolio.Content.Schemas.CaseStudy
  alias Portfolio.Content.Types
  alias Portfolio.Repo

  @test_file_path "test/support/fixtures/case-study/testing-case-study/en.md"

  describe "handle_info/2" do
    test "ignores direct markdown file changes without mutating content" do
      path = @test_file_path
      state = %Watcher{watcher_pid: self()}
      events = [:modified]

      assert Watcher.handle_info({:file_event, self(), {path, events}}, state) ==
               {:noreply, state}

      assert Repo.aggregate(CaseStudy, :count) == 0
    end

    test "returns cleanly for deleted markdown events" do
      path = Path.join(System.tmp_dir!(), "watcher-deleted-note.md")
      state = %Watcher{watcher_pid: self()}

      assert Watcher.handle_info(
               {:file_event, self(), {path, [:deleted]}},
               state
             ) ==
               {:noreply, state}
    end

    test "handle_info/2 ignores irrelevant events on markdown files" do
      path = @test_file_path

      # Define the initial state to match the expected structure
      initial_state = %Watcher{watcher_pid: self()}

      # Call handle_info with the defined state
      result =
        Watcher.handle_info(
          {:file_event, self(), {path, [:modified]}},
          initial_state
        )

      # Assert the expected result
      assert result == {:noreply, initial_state}
    end

    test "ignores hidden markdown files" do
      state = %Watcher{watcher_pid: self()}
      path = Path.join(Types.get_path("case_study"), ".hidden.md")
      events = [:modified]

      assert Watcher.handle_info({:file_event, self(), {path, events}}, state) ==
               {:noreply, state}
    end
  end
end
