defmodule Portfolio.ContentTest do
  use ExUnit.Case, async: true
  alias Portfolio.Content

  describe "read_markdown_file/1" do
    test "reads markdown file successfully" do
      # Assuming a valid file path
      assert {:ok, metadata, markdown} =
               Content.read_markdown_file(
                 "priv/case-study/en/testing_case_study.md"
               )

      assert is_map(metadata)
      assert is_binary(markdown)
    end

    test "returns error for non-existent file" do
      assert {:error, _reason} = Content.read_markdown_file("non_existent.md")
    end

    test "returns error for invalid content format" do
      assert {:error, :missing_frontmatter_delimiters} =
               Content.read_markdown_file(
                 "priv/case-study/en/testing_case_study_malformed.md"
               )
    end
  end

  describe "extract_frontmatter/1" do
    test "extracts frontmatter and content from valid markdown" do
      valid_markdown = """
      ---
      title: Test Title
      date: 2023-01-01
      ---
      # Heading
      Content goes here.
      """

      assert {:ok, %{title: "Test Title", date: "2023-01-01"}} =
               Content.extract_frontmatter(valid_markdown)
    end

    test "Extracts and converts lists of charlists to lists of strings " do
      markdown_with_complex_fields = """
      ---
      title: "Standard title in a simple string"
      platforms: ["list", "of", "strings"]
      ---
      Content goes here.
      """

      assert {:ok, frontmatter} = Content.extract_frontmatter(markdown_with_complex_fields)

      assert frontmatter[:title] == "Standard title in a simple string"
      assert frontmatter[:platforms] == ["list", "of", "strings"]
    end

    test "returns error for missing frontmatter delimiters" do
      no_delimiter_markdown = """
      title: Test Title
      date: 2023-01-01
      # Heading
      Content goes here.
      """

      assert {:error, :missing_frontmatter_delimiters} =
               Content.extract_frontmatter(no_delimiter_markdown)
    end
  end
end
