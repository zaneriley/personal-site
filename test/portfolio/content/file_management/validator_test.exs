defmodule Portfolio.Content.FileManagement.ValidatorTest do
  use Portfolio.DataCase, async: true

  @capture_owned_logs System.get_env("PORTFOLIO_TEST_LOG_LEVEL") != "debug"

  alias Portfolio.Content.FileManagement.Validator
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Repo

  import Portfolio.ContentRepoHelpers

  describe "validate_all/1" do
    test "validates promotable content without persisting it" do
      content_path = tmp_dir!("validate-all")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_note!(content_path, "notes/published-note/en.md")

      assert {:ok, result} = Validator.validate_all(content_path)

      assert result.promoted == [
               Path.expand("notes/published-note/en.md", content_path)
             ]

      refute Repo.get_by(Note, url: "published-note")
    end

    @tag capture_log: @capture_owned_logs
    test "returns promoter errors for invalid content" do
      content_path = tmp_dir!("validate-invalid")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_invalid_note!(content_path, "notes/broken-note/en.md")

      assert {:error, result} = Validator.validate_all(content_path)

      assert [
               %{
                 path: invalid_path,
                 reason: :invalid_markdown_format
               }
             ] = result.errors

      assert invalid_path ==
               Path.expand("notes/broken-note/en.md", content_path)
    end
  end
end
