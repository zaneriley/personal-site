defmodule Portfolio.Content.Utils.MetadataCalculatorTest do
  use ExUnit.Case
  alias Portfolio.Content.Utils.MetadataCalculator

  # Reading speed constants
  # words per minute
  @reading_speed_native_en 238
  # words per minute
  @reading_speed_non_native_en 80
  # words per minute
  @reading_speed_native_en_code 50.0
  # characters per minute
  @reading_speed_ja 600
  # words per minute
  @reading_speed_ja_code 50.0
  # seconds per image
  @image_read_time_seconds 10

  describe "calculate/2" do
    test "calculates word count and read time for English content without images" do
      content = """
      ## Hello World

      This is a sample English text to test the word count and read time calculations.
      """

      locale = "en"

      expected = %{
        word_count: 17,
        image_count: 0,
        non_native_read_time_seconds:
          ceil(17 / @reading_speed_non_native_en * 60),
        native_read_time_seconds: ceil(17 / @reading_speed_native_en * 60),
        code_word_count: 0
      }

      assert {:ok, result} = MetadataCalculator.calculate(content, locale)
      assert result == expected
    end

    test "calculates word count and read time for English content with images" do
      content = """
      ## Hello World

      This is a sample English text to test the word count and read time calculations.

      ![Sample Image](image_url)
      """

      locale = "en"

      expected = %{
        word_count: 17,
        image_count: 1,
        non_native_read_time_seconds:
          ceil(17 / @reading_speed_non_native_en * 60) +
            @image_read_time_seconds,
        native_read_time_seconds:
          ceil(17 / @reading_speed_native_en * 60) + @image_read_time_seconds,
        code_word_count: 0
      }

      assert {:ok, result} = MetadataCalculator.calculate(content, locale)
      assert result == expected
    end

    test "handles very large content efficiently without errors" do
      # 10,000 words
      words = List.duplicate("word", 10_000)
      content = Enum.join(words, " ")

      locale = "en"

      expected_word_count = 10_000

      expected = %{
        word_count: expected_word_count,
        image_count: 0,
        non_native_read_time_seconds:
          ceil(expected_word_count / @reading_speed_non_native_en * 60),
        native_read_time_seconds:
          ceil(expected_word_count / @reading_speed_native_en * 60),
        code_word_count: 0
      }

      assert {:ok, result} = MetadataCalculator.calculate(content, locale)
      assert result == expected
    end

    test "calculates character count and read time for Japanese content" do
      content = """
      こんにちは世界

      これは、単語数と読書時間の計算をテストするための日本語のサンプルテキストです。
      """

      locale = "ja"

      expected = %{
        character_count: 44,
        image_count: 0,
        non_native_read_time_seconds: ceil(44 / @reading_speed_ja * 60),
        native_read_time_seconds: ceil(44 / @reading_speed_ja * 60),
        code_word_count: 0
      }

      assert {:ok, result} = MetadataCalculator.calculate(content, locale)
      assert result == expected
    end

    test "calculates read time with images for Japanese content" do
      content = """
      こんにちは世界

      これは、単語数と読書時間の計算をテストするための日本語のサンプルテキストです。

      ![サンプル画像](image_url)
      """

      locale = "ja"

      expected = %{
        character_count: 44,
        image_count: 1,
        non_native_read_time_seconds:
          ceil(44 / @reading_speed_ja * 60) + @image_read_time_seconds,
        native_read_time_seconds:
          ceil(44 / @reading_speed_ja * 60) + @image_read_time_seconds,
        code_word_count: 0
      }

      assert {:ok, result} = MetadataCalculator.calculate(content, locale)
      assert result == expected
    end

    test "counts words correctly in content with nested lists" do
      content = """
      - Item 1
        - Subitem 1.1
        - Subitem 1.2
      - Item 2
      """

      locale = "en"

      # "Item", "1", "Subitem", "1.1", "Subitem", "1.2", "Item", "2"
      expected_word_count = 8

      expected = %{
        word_count: expected_word_count,
        image_count: 0,
        non_native_read_time_seconds:
          ceil(expected_word_count / @reading_speed_non_native_en * 60),
        native_read_time_seconds:
          ceil(expected_word_count / @reading_speed_native_en * 60),
        code_word_count: 0
      }

      assert {:ok, result} = MetadataCalculator.calculate(content, locale)
      assert result == expected
    end

    test "includes emojis in word count for English content" do
      content = "This is a test 😊 with emojis 👍."

      locale = "en"

      expected = %{
        # "This", "is", "a", "test", "with", "emojis"
        word_count: 6,
        image_count: 0,
        non_native_read_time_seconds:
          ceil(6 / @reading_speed_non_native_en * 60),
        native_read_time_seconds: ceil(6 / @reading_speed_native_en * 60),
        code_word_count: 0
      }

      assert {:ok, result} = MetadataCalculator.calculate(content, locale)
      assert result == expected
    end

    test "handles empty content gracefully" do
      content = ""
      locale = "en"

      expected = %{
        word_count: 0,
        image_count: 0,
        non_native_read_time_seconds: 0,
        native_read_time_seconds: 0,
        code_word_count: 0
      }

      assert {:ok, result} = MetadataCalculator.calculate(content, locale)
      assert result == expected
    end

    test "processes malformed markdown content without crashing" do
      content = """
      # Heading

      Some text here

      [This is a link(https://example.com)

      More text.
      """

      locale = "en"

      expected_word_count = 11

      expected = %{
        word_count: expected_word_count,
        image_count: 0,
        non_native_read_time_seconds:
          ceil(expected_word_count / @reading_speed_non_native_en * 60),
        native_read_time_seconds:
          ceil(expected_word_count / @reading_speed_native_en * 60),
        code_word_count: 0
      }

      assert {:ok, result} = MetadataCalculator.calculate(content, locale)
      assert result == expected
    end

    test "calculates read time with multiple images in English content" do
      content = """
      This content has multiple images to test image counting.

      ![Image 1](image1.jpg)
      ![Image 2](image2.jpg)
      ![Image 3](image3.jpg)
      """

      locale = "en"

      expected = %{
        word_count: 9,
        image_count: 3,
        non_native_read_time_seconds:
          ceil(9 / @reading_speed_non_native_en * 60) +
            3 * @image_read_time_seconds,
        native_read_time_seconds:
          ceil(9 / @reading_speed_native_en * 60) + 3 * @image_read_time_seconds,
        code_word_count: 0
      }

      assert {:ok, result} = MetadataCalculator.calculate(content, locale)
      assert result == expected
    end

    test "Include code blocks from word count in Japanese content" do
      content = """
      ここにサンプルコードがあります。

      ```elixir
      defmodule Sample do
        def hello do
          IO.puts "Hello, world!"
        end
      end
      ```
      """

      locale = "ja"

      # Calculations
      character_count = 15
      code_word_count = 11

      # Text read time
      text_read_time_seconds =
        Float.ceil(character_count / @reading_speed_ja * 60)
        |> trunc()

      # Code read time
      code_read_time_seconds =
        Float.ceil(code_word_count / @reading_speed_ja_code * 60)
        |> trunc()

      # Total read time
      total_read_time_seconds = text_read_time_seconds + code_read_time_seconds

      expected = %{
        character_count: character_count,
        image_count: 0,
        code_word_count: code_word_count,
        native_read_time_seconds: total_read_time_seconds,
        non_native_read_time_seconds: total_read_time_seconds
      }

      assert {:ok, result} = MetadataCalculator.calculate(content, locale)
      assert result == expected
    end

    test "counts words correctly in content with markdown links and formatting" do
      content = """
      This is a [link](https://example.com) with **bold** and *italic* text.
      """

      locale = "en"

      expected = %{
        # "This", "is", "a", "link", "with", "bold", "and", "italic", "text"
        word_count: 9,
        image_count: 0,
        non_native_read_time_seconds:
          ceil(9 / @reading_speed_non_native_en * 60),
        native_read_time_seconds: ceil(9 / @reading_speed_native_en * 60),
        code_word_count: 0
      }

      assert {:ok, result} = MetadataCalculator.calculate(content, locale)
      assert result == expected
    end

    test "returns error tuple for unsupported locale" do
      content = "Sample text"
      locale = "fr"

      expected = {:error, "Unsupported locale: #{locale}"}

      assert MetadataCalculator.calculate(content, locale) == expected
    end
  end

  describe "word_count/2" do
    test "counts words in English content" do
      content = "This is a test sentence."

      locale = "en"

      {:ok, count} = MetadataCalculator.word_count(content, locale)

      assert count == 5
    end

    test "counts characters in Japanese content" do
      content = "これはテスト文です。"

      locale = "ja"

      {:ok, count} = MetadataCalculator.word_count(content, locale)

      assert count == 9
    end
  end

  describe "image_count/1" do
    test "counts images in markdown content" do
      content = """
      ![Image 1](image1.jpg)
      Some text.

      ![Image 2](image2.jpg)
      """

      count = MetadataCalculator.image_count(content)

      assert count == 2
    end

    test "counts images using HTML <img> tags" do
      content = """
      <img src="image.jpg" alt="Alt text" />
      """

      count = MetadataCalculator.image_count(content)

      assert count == 1
    end

    test "returns zero when there are no images" do
      content = "Just some text without any images."

      count = MetadataCalculator.image_count(content)

      assert count == 0
    end
  end

  describe "read_time/3" do
    test "calculates read time range for English content" do
      # 1 minute at native speed
      word_count = @reading_speed_native_en
      image_count = 2
      locale = "en"

      {:ok, read_time} =
        MetadataCalculator.read_time(word_count, image_count, locale)

      expected = %{min: 80, max: 199}

      assert read_time == expected
    end

    test "calculates read time for Japanese content" do
      # 1 minute reading time
      character_count = 600
      image_count = 1
      locale = "ja"

      {:ok, read_time} =
        MetadataCalculator.read_time(character_count, image_count, locale)

      # 1 minute + image time as per requirements
      expected = %{min: 70, max: 70}

      assert read_time == expected
    end
  end

  describe "word_token?/1" do
    test "identifies basic English words" do
      assert MetadataCalculator.word_token?("Hello") == true
      assert MetadataCalculator.word_token?("world") == true
    end

    test "excludes emojis" do
      assert MetadataCalculator.word_token?("😊") == false
      assert MetadataCalculator.word_token?("👍") == false
    end

    test "excludes punctuation" do
      assert MetadataCalculator.word_token?(",") == false
      assert MetadataCalculator.word_token?("!") == false
      assert MetadataCalculator.word_token?(".") == false
    end

    test "excludes symbols" do
      assert MetadataCalculator.word_token?("$") == false
      assert MetadataCalculator.word_token?("&") == false
      assert MetadataCalculator.word_token?("@") == false
    end

    test "identifies words with contractions" do
      assert MetadataCalculator.word_token?("don't") == true
      assert MetadataCalculator.word_token?("can't") == true
    end

    test "identifies hyphenated words" do
      assert MetadataCalculator.word_token?("mother-in-law") == true
      assert MetadataCalculator.word_token?("part-time") == true
    end

    test "identifies alphanumeric words" do
      assert MetadataCalculator.word_token?("C3PO") == true
      assert MetadataCalculator.word_token?("version2") == true
    end

    test "excludes numbers" do
      assert MetadataCalculator.word_token?("12345") == true
      assert MetadataCalculator.word_token?("2.0") == true
    end

    test "identifies words in other scripts" do
      # Japanese
      assert MetadataCalculator.word_token?("こんにちは") == true
      # Arabic
      assert MetadataCalculator.word_token?("مرحبا") == true
      # Russian
      assert MetadataCalculator.word_token?("привет") == true
    end

    test "excludes whitespace" do
      assert MetadataCalculator.word_token?(" ") == false
      assert MetadataCalculator.word_token?("\n") == false
      assert MetadataCalculator.word_token?("\t") == false
    end

    test "handles mixed content" do
      assert MetadataCalculator.word_token?("Hello😊") == true
      assert MetadataCalculator.word_token?("🚀Launch") == true
      assert MetadataCalculator.word_token?("goodbye👋") == true
    end

    test "handles edge cases with special characters" do
      assert MetadataCalculator.word_token?("-") == false
      assert MetadataCalculator.word_token?("--") == false
      # em dash
      assert MetadataCalculator.word_token?("—") == false
    end
  end
end
