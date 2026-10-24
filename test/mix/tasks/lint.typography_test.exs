defmodule Mix.Tasks.Lint.TypographyTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Mix.Tasks.Lint.Typography

  describe "violations/2" do
    test "reports standalone paragraphs, including conditional and multiline opening tags" do
      source = """
      <section>
        <p
          :if={@visible}
          class="example"
        >Text</p>
        <p :for={item <- @items}>{item}</p>
      </section>
      """

      assert [
               %{file: "example.heex", line: 2, column: 3},
               %{file: "example.heex", line: 6, column: 3}
             ] = Typography.violations(source, "example.heex")
    end

    test "preserves original heredoc source line and indentation" do
      source = ~S'''
      defmodule Example do
        def render(assigns) do
          ~H"""
          <section>
            <p>Text</p>
          </section>
          """
        end
      end
      '''

      assert [%{file: "example.ex", line: 5, column: 7}] =
               Typography.violations(source, "example.ex")
    end

    test "finds every inline template and preserves same-line columns" do
      source = "first = ~H\"<p>One</p>\"\nsecond = ~H\"<p>Two</p>\"\n"

      assert [
               %{file: "example.ex", line: 1, column: 12},
               %{file: "example.ex", line: 2, column: 13}
             ] = Typography.violations(source, "example.ex")
    end

    test "does not mistake paragraph strings, comments, or longer tag names for tags" do
      source = ~S'''
      <!-- <p>HTML example</p> -->
      <%!-- <p>HEEx example</p> --%>
      <div title="<p>example</p>" data-example={"<p>expression</p>"}>
        {"<p>text</p>"}
        <.typography tag="p">Supported paragraph</.typography>
        <pre>&lt;p&gt;Escaped example&lt;/p&gt;</pre>
        <picture><img src="example.png" /></picture>
      </div>
      <script>const example = "<p>JavaScript string</p>";</script>
      '''

      assert Typography.violations(source, "example.heex") == []
    end

    test "ignores ordinary Elixir strings, docstrings, comments, and other sigils" do
      source = ~S'''
      defmodule Example do
        @moduledoc """
        Use <p>example</p> or ~H"<p>example</p>" in this illustration.
        """
        # ~H"<p>comment</p>"
        @example "<p>ordinary string</p>"
        @raw ~S(<p>other sigil</p>)
        def render(assigns), do: ~H"<.typography tag='p'>Text</.typography>"
      end
      '''

      assert Typography.violations(source, "example.ex") == []
    end

    test "checks HEEx emitted by quoted macros" do
      source = ~S'''
      defmacro example do
        quote do
          ~H"<p>Generated paragraph</p>"
        end
      end
      '''

      assert [%{file: "macro.ex", line: 3, column: 8}] =
               Typography.violations(source, "macro.ex")
    end

    test "does not exempt arbitrary development pages or component directories" do
      source = "def render(assigns), do: ~H\"<p>Unstyled</p>\""

      for path <- [
            "lib/portfolio_web/components/new_component.ex",
            "lib/portfolio_web/live/dev/new_calibration_live.ex"
          ] do
        assert [%{file: ^path}] = Typography.violations(source, path)
      end
    end

    test "requires a per-paragraph marker even inside a named calibration page" do
      path =
        "lib/portfolio_web/controllers/dev_html/weight_calibration.html.heex"

      source = "<p data-typography-calibration>Specimen</p>\n<p>Unstyled</p>\n"

      assert [%{file: ^path, line: 2, column: 1}] =
               Typography.violations(source, path)
    end

    test "calibration marker cannot exempt product UI or sibling calibration files" do
      source = "<p data-typography-calibration>Unstyled</p>"

      for path <- [
            "lib/portfolio_web/controllers/page_html/home.html.heex",
            "lib/portfolio_web/controllers/dev_html/new_calibration.html.heex"
          ] do
        assert [%{file: ^path, line: 1, column: 1}] =
                 Typography.violations(source, path)
      end
    end

    test "calibration marker must be an explicit boolean attribute" do
      path =
        "lib/portfolio_web/controllers/dev_html/weight_calibration.html.heex"

      for marker <- [
            ~s(data-typography-calibration="false"),
            "data-typography-calibration={@flag}"
          ] do
        assert [%{file: ^path}] =
                 Typography.violations("<p #{marker}>Text</p>", path)
      end
    end

    test "raises rather than silently approving malformed Elixir" do
      assert_raise TokenMissingError, fn ->
        Typography.violations(
          "defmodule Example do\n  def broken(",
          "broken.ex"
        )
      end
    end

    test "raises rather than silently approving malformed HEEx" do
      assert_raise Phoenix.LiveView.TagEngine.Tokenizer.ParseError, fn ->
        Typography.violations("<div title=\"unterminated", "broken.heex")
      end
    end
  end

  describe "run/1" do
    @tag :tmp_dir
    test "fails on an actual paragraph and tells the author which component to use",
         %{
           tmp_dir: directory
         } do
      path = Path.join(directory, "bad.heex")
      File.write!(path, "<section>\n  <p>Unstyled</p>\n</section>\n")

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert_raise Mix.Error, ~r/Typography lint failed/, fn ->
            Typography.run([path])
          end
        end)

      assert output =~ "#{path}:2:3:"
      assert output =~ ~s(use <.typography tag="p"> instead)
    end

    @tag :tmp_dir
    test "accepts the typography component", %{tmp_dir: directory} do
      path = Path.join(directory, "good.heex")
      File.write!(path, "<.typography tag=\"p\">Styled</.typography>\n")

      Typography.run([path])
    end
  end
end
