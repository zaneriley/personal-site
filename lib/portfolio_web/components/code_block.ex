defmodule PortfolioWeb.Components.CodeBlock do
  @moduledoc """
  A framed source-code listing: a header carrying the file path (directory
  de-emphasized, basename emphasized) or a language label, a copy button, a
  line-number gutter, and a scrollable code area with a bottom scrim as the
  scroll affordance.

  Presentation only. The component consumes code that is *already classified* —
  HTML whose token spans carry the `tok-*` classes (see `assets/css/_code.css`
  for the class contract) — typically baked at content-compile time by the
  markdown pipeline's tokenizer. It never tokenizes, and it never needs to:
  an unclassified plain string renders as uncolored code, which is the
  intended fallback for unknown languages.

  Line numbers are derived from the code, never authored. The copy affordance
  reads the rendered code's text content client-side, so the source ships
  exactly once.

  ## Example Usage

      <.code_block language="elixir" filename="lib/portfolio/content.ex" code={@classified} />
      <.code_block language="bash" code="mix phx.server" />
  """

  use Phoenix.Component

  use Portfolio.Content.Markdown.Component.Definition,
    type: :code_block,
    function: :code_block,
    description:
      "A framed, line-numbered source-code listing with a file path or language label",
    attributes: %{
      code: %{
        type: :any,
        required: true,
        description:
          "The source code: classified HTML (safe, tok-* spans) or a plain string to render uncolored"
      },
      language: %{
        type: :string,
        required: false,
        default: nil,
        description:
          "The source language, shown as the header label when there is no filename"
      },
      filename: %{
        type: :string,
        required: false,
        default: nil,
        description: "The path the code comes from, shown in the header"
      }
    },
    examples: [
      """
      <.code_block language="elixir" filename="lib/portfolio/content.ex" code={@classified} />
      """
    ]

  use Gettext, backend: PortfolioWeb.Gettext

  alias PortfolioWeb.Components.Typography

  attr :code, :any,
    required: true,
    doc:
      "classified HTML as {:safe, _} (tok-* spans) or a plain string, which gets escaped"

  attr :language, :string, default: nil
  attr :filename, :string, default: nil

  @doc """
  Renders the code-block component.

  The first clause is the markdown pipeline's entry point: the renderer applies
  registered components with `%{component:, attrs:, content:}` (attrs are
  string-keyed after DB round-tripping) and string-joins the result, so this
  clause normalizes to the component's attrs and returns the rendered binary.
  The baked `code` HTML is our own compile-time tokenizer output — trusted.
  """
  @spec code_block(map()) :: Phoenix.LiveView.Rendered.t() | String.t()
  def code_block(%{component: :code_block, attrs: attrs}) do
    %{
      code: {:safe, Map.fetch!(attrs, "code")},
      language: Map.get(attrs, "language"),
      filename: Map.get(attrs, "filename"),
      __changed__: nil
    }
    |> code_block()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  def code_block(assigns) do
    code = ensure_safe(assigns.code)

    assigns =
      assigns
      |> assign(:code, code)
      |> assign(:line_numbers, line_numbers(code))
      |> assign(:path, split_path(assigns.filename))

    ~H"""
    <div class="code-block">
      <div class="code-block-header">
        <p :if={@path} class="code-block-filename">
          <span :if={@path.dir} class="code-block-dir">{@path.dir}</span><span class="code-block-name">{@path.name}</span>
        </p>
        <Typography.typography
          :if={is_nil(@path) && @language}
          tag="span"
          size="2xs"
          class="code-block-language caps"
        >
          {@language}
        </Typography.typography>
        <button
          class="code-block-copy"
          type="button"
          aria-label={gettext("Copy code")}
        >
          ⧉
        </button>
      </div>
      <div class="code-block-body">
        <div class="code-block-frame" aria-hidden="true"></div>
        <div class="code-block-scroll">
          <div class="code-block-gutter" aria-hidden="true">{@line_numbers}</div>
          <div class="code-block-code-scroll">
            <code class="code-block-code">{@code}</code>
          </div>
        </div>
      </div>
      <div class="code-block-scrim" aria-hidden="true"></div>
    </div>
    """
  end

  # The code attr is honest about trust: a plain string is escaped here; only
  # already-safe HTML (the pipeline's classified output, or a caller's explicit
  # raw/1) passes through unescaped.
  @spec ensure_safe(Phoenix.HTML.safe() | String.t()) :: Phoenix.HTML.safe()
  defp ensure_safe({:safe, _} = safe), do: safe

  defp ensure_safe(code) when is_binary(code),
    do: Phoenix.HTML.html_escape(code)

  # "1\n2\n…n" for the gutter, derived from the rendered code's line count.
  # Newlines in the classified HTML are the source's real newlines (token spans
  # never introduce their own), so counting them counts source lines.
  @spec line_numbers(Phoenix.HTML.safe()) :: String.t()
  defp line_numbers({:safe, iodata}) do
    count =
      iodata
      |> IO.iodata_to_binary()
      |> String.trim_trailing("\n")
      |> String.split("\n")
      |> length()

    Enum.map_join(1..count, "\n", &Integer.to_string/1)
  end

  # Header path: directory run de-emphasized, basename emphasized. A bare
  # filename has no directory part to dim.
  @spec split_path(String.t() | nil) ::
          %{dir: String.t() | nil, name: String.t()} | nil
  defp split_path(nil), do: nil

  defp split_path(filename) do
    case Path.dirname(filename) do
      "." -> %{dir: nil, name: filename}
      dir -> %{dir: dir <> "/", name: Path.basename(filename)}
    end
  end
end
