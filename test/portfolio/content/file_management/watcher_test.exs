defmodule Portfolio.Content.FileManagement.WatcherTest do
  use ExUnit.Case
  alias Portfolio.Content.FileManagement.Watcher
  alias Portfolio.Content.Types
  import ExUnit.CaptureLog
  use Portfolio.DataCase

  @test_file_path "test/support/fixtures/case-study/testing-case-study/en.md"
  @malformed_file_path "test/support/fixtures/case-study/testing-case-study-malformed/en.md"

  describe "handle_info/2" do
    test "processes relevant file changes" do
      path = @test_file_path
      state = %Watcher{watcher_pid: self()}
      events = [:modified]

      log =
        capture_log(fn ->
          Logger.configure(level: :debug)
          Watcher.handle_info({:file_event, self(), {path, events}}, state)
        end)

      assert log =~ "File event detected: #{path}"
      assert log =~ "Processing file change for: #{path}"
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

      log =
        capture_log(fn ->
          Watcher.handle_info({:file_event, self(), {path, events}}, state)
        end)

      refute log =~ "Processing file change for: #{path}"
    end
  end
end
