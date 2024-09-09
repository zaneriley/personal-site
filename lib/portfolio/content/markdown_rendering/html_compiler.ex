defmodule Portfolio.Content.MarkdownRendering.HTMLCompiler do
  @moduledoc """
  Renders the schema-specific Abstract Syntax Tree (AST) to HTML, including custom UI components.

  This module provides functionality to transform an AST representation of content
  into HTML, handling both standard HTML tags and custom components like images.
  """

  require Logger

  @type ast_node ::
          {binary(), list(), list() | binary(), map()}
          | {:custom_image, binary(), binary(), map()}
          | binary()
  @type render_opts :: keyword()

  @doc """
  Renders the given content AST to HTML.

  ## Parameters
    - content: A map containing the AST to be rendered.
    - opts: Optional keyword list of rendering options (currently unused).

  ## Returns
    - `{:ok, html}` if rendering is successful, where `html` is the rendered HTML string.
    - `{:error, reason}` if rendering fails, where `reason` is an error message.
  """
  @spec render(map(), render_opts()) :: {:ok, String.t()} | {:error, String.t()}
  def render(content, opts \\ [])

  def render(%{ast: ast}, _opts) when is_list(ast) do
    html = Enum.map_join(ast, "", &transform/1)
    {:ok, html}
  end

  def render(_, _opts) do
    Logger.error("Invalid content provided to HTMLCompiler")
    {:error, "Invalid content"}
  end

  @doc """
  Transforms an AST node into its HTML representation.

  ## Parameters
    - node: An AST node to be transformed.

  ## Returns
    - A string or list of strings representing the HTML for the given node.
  """
  @spec transform(ast_node()) :: String.t() | [String.t()]
  def transform({tag, attrs, content, _meta}) when is_binary(tag) do
    attributes = transform_attributes(attrs)
    transformed_content = transform_content(content)
    ["<#{tag}#{attributes}>", transformed_content, "</#{tag}>"]
  end

  # coveralls-ignore-start
  def transform({:custom_image, alt, src, attrs}) do
    caption = Map.get(attrs, "caption", "")
    srcset = Map.get(attrs, "srcset", "")

    """
    <figure class="responsive-image">
      <img src="#{src}" alt="#{alt}" srcset="#{srcset}">
      <figcaption>#{caption}</figcaption>
    </figure>
    """
  end

  # coveralls-ignore-stop

  def transform(content) when is_binary(content), do: content

  @spec transform_attributes(list({String.t(), String.t()})) :: String.t()
  defp transform_attributes(attrs) do
    Enum.map_join(attrs, "", fn {key, value} -> " #{key}=\"#{value}\"" end)
  end

  @spec transform_content(list(ast_node()) | String.t()) :: String.t()
  defp transform_content(content) when is_list(content) do
    Enum.map_join(content, "", &transform/1)
  end

  defp transform_content(content) when is_binary(content), do: content
end
