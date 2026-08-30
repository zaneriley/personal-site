defmodule Portfolio.Content.FileManagement.ReaderTest do
  use ExUnit.Case
  alias Portfolio.Content.FileManagement.Reader
  alias Portfolio.Content.Types
  import ExUnit.CaptureLog

  @test_file_path "test/support/fixtures/case-study/testing-case-study/en.md"
  @malformed_file_path "test/support/fixtures/case-study/testing-case-study-malformed/en.md"

  describe "read_markdown_file/1" do
    test "reads valid markdown file successfully" do
      path = @test_file_path
      assert {:ok, content_type, attrs} = Reader.read_markdown_file(path)

      assert content_type == "case_study"
      assert is_map(attrs)
      assert Map.has_key?(attrs, "content")
      assert Map.has_key?(attrs, "file_path")
      assert Map.has_key?(attrs, "locale")

      assert attrs["title"] ==
               "Test case study. Emoji: 👋 Numbers: 1234567890 Japanese: いろはにほへと ！＂＃＄％＆＇（）＊＋，－．／０１２３４５６７８９：；＜＝＞？＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱ｀ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ｛｜｝～｡｢｣､･ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂ YAHAHAHA!"

      assert attrs["url"] == "testing-case-study"
      assert attrs["platforms"] == ["List", "of", "strings"]
      assert attrs["content"] =~ "# Heading Level 1"
    end

    test "returns error for non-existent file" do
      path = Path.join(Types.get_path("note"), "non-existent.md")

      assert capture_log(fn ->
               assert {:error, _reason} = Reader.read_markdown_file(path)
             end) =~ "Error reading markdown file: #{path}"
    end

    test "returns error for invalid content format" do
      path = @malformed_file_path

      assert capture_log(fn ->
               assert {:error, :invalid_markdown_format} =
                        Reader.read_markdown_file(path)
             end) =~ "Error reading markdown file"
    end

    test "extracts locale from file path" do
      path = @test_file_path
      assert {:ok, _content_type, attrs} = Reader.read_markdown_file(path)
      assert attrs["locale"] == "en"
    end

    test "handles frontmatter with various data types" do
      assert {:ok, "case_study", attrs} =
               Reader.read_markdown_file(@test_file_path)

      assert is_integer(attrs["read_time"])
      assert is_list(attrs["platforms"])
      assert is_boolean(attrs["is_draft"])
    end
  end
end
