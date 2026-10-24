defmodule Mix.Tasks.Lint.Typography do
  @moduledoc """
  Rejects raw paragraph tags in application HEEx.

  Run through `./run elixir:lint`, or `./run mix lint.typography [paths...]`.
  Paragraphs must use `<.typography tag="p">` so typography behavior is shared.
  Calibration specimens may opt out with `data-typography-calibration`, but only
  in the explicitly named calibration pages below. Unmarked additions still fail.
  """

  use Mix.Task

  alias Phoenix.LiveView.TagEngine.Parser

  @calibration_files ~w(
    lib/portfolio_web/controllers/dev_html/hdr_lab.html.heex
    lib/portfolio_web/controllers/dev_html/weight_calibration.html.heex
    lib/portfolio_web/controllers/dev_html/color_tokens.html.heex
    lib/portfolio_web/live/palette_comparison_live.ex
    lib/portfolio_web/live/color_sketch_live.ex
    lib/portfolio_web/live/shader_scale_sketch_live.ex
    lib/portfolio_web/live/dark_background_sketch_live.ex
  )

  @impl Mix.Task
  @spec run([String.t()]) :: :ok
  def run(args) do
    Mix.Task.run("loadpaths")
    paths = if args == [], do: Path.wildcard("lib/**/*.{ex,heex}"), else: args
    violations = Enum.flat_map(paths, &violations(File.read!(&1), &1))

    if violations != [] do
      Enum.each(violations, fn %{file: file, line: line, column: column} ->
        Mix.shell().error(
          "#{file}:#{line}:#{column}: raw <p> bypasses typography; " <>
            "use <.typography tag=\"p\"> instead"
        )
      end)

      Mix.raise(
        "Typography lint failed: #{length(violations)} raw paragraph(s)"
      )
    end

    Mix.shell().info("Typography lint passed (#{length(paths)} files)")
  end

  @doc false
  @spec violations(String.t(), String.t()) :: [map()]
  def violations(source, path) do
    templates =
      if Path.extname(path) == ".heex" do
        [{source, 0, 0, 0}]
      else
        source
        |> Code.string_to_quoted!(file: path, columns: true)
        |> templates()
      end

    Enum.flat_map(templates, &paragraphs(&1, path))
  end

  defp templates({:sigil_H, meta, [{:<<>>, content_meta, [source]}, _]})
       when is_binary(source) do
    if meta[:delimiter] in ["\"\"\"", "'''"] do
      [{source, meta[:line], content_meta[:indentation] || 0, 0}]
    else
      [{source, meta[:line] - 1, 0, meta[:column] + 2}]
    end
  end

  defp templates(tuple) when is_tuple(tuple) do
    tuple |> Tuple.to_list() |> Enum.flat_map(&templates/1)
  end

  defp templates(list) when is_list(list), do: Enum.flat_map(list, &templates/1)
  defp templates(_other), do: []

  defp paragraphs({source, line_offset, indentation, first_column_offset}, path) do
    source
    |> Parser.tokenize(tag_handler: Phoenix.LiveView.HTMLEngine, file: path)
    |> Enum.flat_map(
      &paragraph(&1, path, line_offset, indentation, first_column_offset)
    )
  end

  defp paragraph(
         {:tag, "p", attrs, %{line: line, column: column}},
         path,
         line_offset,
         indentation,
         first_column_offset
       ) do
    if calibration?(attrs, path) do
      []
    else
      column_offset = if line == 1, do: first_column_offset, else: 0

      [
        %{
          file: path,
          line: line + line_offset,
          column: column + indentation + column_offset
        }
      ]
    end
  end

  defp paragraph(
         _token,
         _path,
         _line_offset,
         _indentation,
         _first_column_offset
       ),
       do: []

  defp calibration?(attrs, path) do
    Path.relative_to_cwd(path) in @calibration_files and
      Enum.any?(attrs, fn {name, value, _meta} ->
        name == "data-typography-calibration" and is_nil(value)
      end)
  end
end
