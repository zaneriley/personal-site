defmodule PortfolioWeb.Components.ContentMetadataTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PortfolioWeb.Components.ContentMetadata
  import PortfolioWeb.Gettext
  alias Timex

  describe "content_metadata/1" do
    test "renders read time when read_time is an integer" do
      assigns = %{read_time: 360}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "6 min read"
    end

    test "renders read time when read_time is a string representing an integer" do
      assigns = %{read_time: "360"}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "6 min read"
    end

    test "renders 'Less than 1 minute read' when read_time <= 60 seconds" do
      assigns = %{read_time: 45}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "1 min read"
    end

    test "does not render read time when read_time is nil" do
      assigns = %{read_time: nil}

      html = render_component(&content_metadata/1, assigns)

      refute html =~ "word"
    end

    test "does not render read time for invalid read_time string" do
      assigns = %{read_time: "invalid"}

      html = render_component(&content_metadata/1, assigns)
      refute html =~ "minute read"
    end

    test "renders word count correctly with proper pluralization" do
      assigns = %{word_count: 1}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "1 word"

      assigns = %{word_count: 250}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "250 words"
    end

    test "parses and renders word count when provided as a string" do
      assigns = %{word_count: "250"}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "250 words"
    end

    test "does not render word count for invalid word_count string" do
      assigns = %{word_count: "invalid"}

      html = render_component(&content_metadata/1, assigns)
      refute html =~ "word"
    end

    test "does not render word count when both word_count and character_count are nil" do
      assigns = %{word_count: nil, character_count: nil}

      html = render_component(&content_metadata/1, assigns)

      refute html =~ "word"
      refute html =~ "character"
    end

    test "renders updated date as 'Updated today' when updated_at is today" do
      assigns = %{updated_at: Timex.now()}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "Updated today"
    end

    test "renders updated date as 'Updated yesterday' when updated_at is yesterday" do
      assigns = %{updated_at: Timex.shift(Timex.now(), days: -1)}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "Updated yesterday"
    end

    test "renders formatted date when updated_at is older than yesterday" do
      updated_at = Timex.shift(Timex.now(), days: -3)
      assigns = %{updated_at: updated_at, user_locale: "en"}

      html = render_component(&content_metadata/1, assigns)

      formatted_date = Timex.format!(updated_at, "%b %-d, %Y", :strftime)

      assert html =~ "Updated #{formatted_date}"
    end

    test "does not render updated date when updated_at is nil" do
      assigns = %{updated_at: nil}
      html = render_component(&content_metadata/1, assigns)

      {:ok, parsed} = Floki.parse_fragment(html)
      assert Floki.text(parsed) == ""
    end

    test "does not add leading separator when only one metadata segment is rendered" do
      assigns = %{read_time: 360}

      html = render_component(&content_metadata/1, assigns)

      # The separator should not be at the start
      refute String.starts_with?(html, gettext("Metadata separator"))
    end

    test "renders dates formatted according to the user_locale" do
      updated_at = Timex.shift(Timex.now(), days: -3)
      assigns = %{updated_at: updated_at, user_locale: "ja"}

      html = render_component(&content_metadata/1, assigns)

      formatted_date = Timex.format!(updated_at, "%Y年%-m月%-d日", :strftime)

      assert html =~ "Updated #{formatted_date}"
    end

    test "uses gettext pluralization rules based on user_locale" do
      Gettext.put_locale("en")
      assigns = %{word_count: 1, user_locale: "en"}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "1 word"

      assigns = %{word_count: 2, user_locale: "en"}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "2 words"
    end

    test "fetches user_locale when not explicitly provided" do
      # Set the default locale
      Gettext.put_locale("en")

      assigns = %{read_time: 360}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "6 min read"
    end

    test "handles large numbers with delimiters" do
      assigns = %{word_count: 1_000_000}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "1,000,000 words"
    end

    test "does not render when invalid data is provided" do
      assigns = %{read_time: :invalid}
      html = render_component(&content_metadata/1, assigns)

      {:ok, parsed} = Floki.parse_fragment(html)
      assert Floki.text(parsed) == ""
    end

    test "renders empty string when all metadata attributes are nil" do
      assigns = %{}
      html = render_component(&content_metadata/1, assigns)

      {:ok, parsed} = Floki.parse_fragment(html)
      assert Floki.text(parsed) == ""
    end

    test "does not render content when all attributes are invalid" do
      assigns = %{read_time: "invalid", word_count: "invalid", updated_at: nil}
      html = render_component(&content_metadata/1, assigns)

      {:ok, parsed} = Floki.parse_fragment(html)
      assert Floki.text(parsed) == ""
    end

    test "handles zero word count properly" do
      assigns = %{word_count: 0}

      html = render_component(&content_metadata/1, assigns)

      assert html =~ "0 words"
    end
  end
end
