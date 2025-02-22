defmodule Portfolio.Content.MarkdownRendering.HTMLCompiler do
  @moduledoc """
  Transforms parsed Markdown AST into a Component AST that can be rendered
  with Phoenix components.
  """

  require Logger
  alias PortfolioWeb.Components.Typography

  @doc """
  Renders the given content AST to a Component AST.

  ## Parameters
    - content: A map containing the AST to be rendered
    - opts: Optional keyword list of rendering options

  ## Returns
    - {:ok, component_ast} if rendering is successful
    - {:error, reason} if rendering fails
  """
  @spec render(map(), keyword()) :: {:ok, term()} | {:error, String.t()}
  def render(%{ast: ast}, opts \\ []) when is_list(ast) do
    try do
      component_ast = Enum.map(ast, &transform_node/1)
      {:ok, component_ast}
    rescue
      e ->
        Logger.error("Failed to compile AST: #{inspect(e)}")
        {:error, "Failed to compile content"}
    end
  end

  def render(_, _opts) do
    Logger.error("Invalid content provided to HTMLCompiler")
    {:error, "Invalid content"}
  end

  # Transform heading nodes to typography components
  defp transform_node({:heading, level, content, meta}) do
    {:component, Typography, :typography,
     %{
       tag: "h#{level}",
       size: get_size_for_heading(level),
       dropcap: false
     }, transform_content(content)}
  end

  # Transform paragraph nodes to typography components
  defp transform_node({:paragraph, _attrs, content, meta}) do
    {:component, Typography, :typography,
     %{
       tag: "p",
       size: "md",
       dropcap: meta[:first_paragraph] || false
     }, transform_content(content)}
  end

  # Transform text nodes
  defp transform_node(content) when is_binary(content), do: content

  # Transform lists of nodes
  defp transform_content(content) when is_list(content) do
    Enum.map(content, &transform_node/1)
  end

  defp transform_content(content), do: content

  defp get_size_for_heading(level) do
    case level do
      1 -> "4xl"
      2 -> "3xl"
      3 -> "2xl"
      4 -> "1xl"
      5 -> "1xs"
      _ -> "1xs"
    end
  end
end
