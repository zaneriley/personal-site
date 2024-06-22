defmodule Portfolio.ContentTest do
  use ExUnit.Case, async: true
  use Portfolio.DataCase
  import Portfolio.AdminFixtures
  alias Portfolio.Content
  import ExUnit.CaptureLog

  describe "update_case_study_from_file/1" do
    setup do
      case_study = case_study_fixture()
      %{case_study: case_study}
    end

    test "updates case study successfully from a valid Markdown file", %{
      case_study: case_study
    } do
      valid_file_path = "priv/case-study/en/testing-case-study.md"

      result = Content.update_case_study_from_file(valid_file_path)

      assert {:ok, {:ok, updated_case_study}} = result
      assert updated_case_study.url == "testing-case-study"
    end

    test "returns error for missing file path" do
      assert capture_log(fn ->
               assert {:error, :file_path_missing} =
                        Content.update_case_study_from_file(nil)
             end) =~ "File path is nil"
    end

    test "returns error for missing delimiters in file" do
      invalid_file = "priv/case-study/en/testing-case-study-malformed.md"

      assert capture_log(fn ->
               assert {:error, :missing_frontmatter_delimiters} =
                        Content.update_case_study_from_file(invalid_file)
             end) =~
               "Error extracting content from file priv/case-study/en/testing-case-study-malformed.md. Reason: missing_frontmatter_delimiters"
    end
  end
end
