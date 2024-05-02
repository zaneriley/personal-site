defmodule Portfolio.Content.FileSystemWatcherTest do
  use ExUnit.Case, async: true
  alias Portfolio.Content.FileSystemWatcher
  alias Portfolio.Content

  describe "relevant_file_change?/2" do
    test "returns true for relevant markdown file changes" do
      assert FileSystemWatcher.relevant_file_change?("example.md", [:modified, :closed])
    end

    test "returns false for non-markdown file changes" do
      refute FileSystemWatcher.relevant_file_change?("example.txt", [:modified, :closed])
    end

    test "returns false for irrelevant events on markdown files" do
      assert FileSystemWatcher.relevant_file_change?("example.md", [:created])
    end

    test "returns false for hidden markdown files" do
      refute FileSystemWatcher.relevant_file_change?(".hidden.md", [:modified, :closed])
    end
  end

end
