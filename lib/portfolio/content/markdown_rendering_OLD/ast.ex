defmodule Portfolio.Content.MarkdownRendering.AST do
  @moduledoc """
  Defines the Abstract Syntax Tree (AST) structure for markdown content and
  provides tools for creating, manipulating, and traversing AST nodes.

  The AST represents the parsed structure of markdown content, with specialized
  nodes for components and text elements. This module serves as the foundation
  for the transformation pipeline that converts markdown to Phoenix components.
  """

  @typedoc """
  A node in the AST representing a markdown element or custom component.

  Node types:
  - `:text` - Plain text content
  - `:element` - Standard HTML element (p, h1, ul, etc.)
  - `:component` - Custom component reference
  """
  @type ast_node :: text_node() | element_node() | component_node()

  @typedoc "A plain text node"
  @type text_node :: String.t()

  @typedoc "A standard HTML element node with tag, attributes, and children"
  @type element_node ::
          {tag :: String.t(), attrs :: attrs(), content :: [ast_node()],
           meta :: meta()}

  @typedoc "A custom component node with component type, attributes, and content"
  @type component_node ::
          {:component, type :: atom(), attrs :: attrs(),
           content :: [ast_node()], meta :: meta()}

  @typedoc "A map of attribute key-value pairs"
  @type attrs :: %{optional(atom()) => any()}

  @typedoc "Metadata associated with a node"
  @type meta :: %{optional(atom()) => any()}

  @typedoc "A complete AST representing a markdown document"
  @type t :: [ast_node()]

  @doc """
  Creates a text node from a string.

  ## Examples

      iex> AST.text("Hello world")
      "Hello world"
  """
  @spec text(String.t()) :: text_node()
  def text(content) when is_binary(content), do: content

  @doc """
  Creates an element node with the given tag, attributes, and content.

  ## Examples

      iex> AST.element("p", %{class: "intro"}, ["Hello world"], %{})
      {"p", %{class: "intro"}, ["Hello world"], %{}}
  """
  @spec element(String.t(), attrs(), [ast_node()], meta()) :: element_node()
  def element(tag, attrs \\ %{}, content \\ [], meta \\ %{})
      when is_binary(tag) and is_map(attrs) and is_list(content) and
             is_map(meta) do
    {tag, attrs, content, meta}
  end

  @doc """
  Creates a component node with the given type, attributes, and content.

  ## Examples

      iex> AST.component(:column_layout, %{columns: 2}, ["Content"], %{})
      {:component, :column_layout, %{columns: 2}, ["Content"], %{}}
  """
  @spec component(atom(), attrs(), [ast_node()], meta()) :: component_node()
  def component(type, attrs \\ %{}, content \\ [], meta \\ %{})
      when is_atom(type) and is_map(attrs) and is_list(content) and is_map(meta) do
    {:component, type, attrs, content, meta}
  end

  @doc """
  Creates a typography component node with the specified tag, attributes, and content.

  ## Examples

      iex> AST.typography("h1", %{size: "4xl"}, ["My Heading"], %{})
      {:component, :typography, %{tag: "h1", size: "4xl"}, ["My Heading"], %{}}
  """
  @spec typography(String.t(), attrs(), [ast_node()], meta()) ::
          component_node()
  def typography(tag, attrs \\ %{}, content \\ [], meta \\ %{})
      when is_binary(tag) and is_map(attrs) and is_list(content) and
             is_map(meta) do
    component_attrs = Map.merge(attrs, %{tag: tag})
    component(:typography, component_attrs, content, meta)
  end

  @doc """
  Maps a function over all nodes in an AST, transforming each node.

  This is a core utility for AST transformation pipelines.

  ## Examples

      iex> AST.map(["Hello", {"p", %{}, ["World"], %{}}], fn
      ...>   node when is_binary(node) -> String.upcase(node)
      ...>   node -> node
      ...> end)
      ["HELLO", {"p", %{}, ["World"], %{}}]
  """
  @spec map(t(), (ast_node() -> ast_node())) :: t()
  def map(ast, fun) when is_list(ast) and is_function(fun, 1) do
    Enum.map(ast, fn
      {tag, attrs, content, meta} = node when is_binary(tag) ->
        # Handle element node
        case fun.(node) do
          {^tag, ^attrs, ^content, ^meta} ->
            # If the node wasn't changed by the function, still map children
            {tag, attrs, map(content, fun), meta}

          transformed_node ->
            # If the function changed the node, return it as is
            transformed_node
        end

      {:component, type, attrs, content, meta} = node ->
        # Handle component node
        case fun.(node) do
          {:component, ^type, ^attrs, ^content, ^meta} ->
            # If the node wasn't changed by the function, still map children
            {:component, type, attrs, map(content, fun), meta}

          transformed_node ->
            # If the function changed the node, return it as is
            transformed_node
        end

      node ->
        # Handle text node or other types
        fun.(node)
    end)
  end

  @doc """
  Finds all nodes in an AST that match a predicate function.

  ## Examples

      iex> AST.find_all([
      ...>   {"h1", %{}, ["Title"], %{}},
      ...>   {"p", %{}, ["Paragraph"], %{}}
      ...> ], fn
      ...>   {"h1", _, _, _} -> true
      ...>   _ -> false
      ...> end)
      [{"h1", %{}, ["Title"], %{}}]
  """
  @spec find_all(t(), (ast_node() -> boolean())) :: [ast_node()]
  def find_all(ast, predicate)
      when is_list(ast) and is_function(predicate, 1) do
    Enum.reduce(ast, [], fn
      node, acc ->
        # First, check if the current node matches
        matches =
          if predicate.(node) do
            [node | acc]
          else
            acc
          end

        # Then recursively check children if applicable
        case node do
          {_tag, _attrs, content, _meta} when is_list(content) ->
            # For elements, check children
            find_all(content, predicate) ++ matches

          {:component, _type, _attrs, content, _meta} when is_list(content) ->
            # For components, check children
            find_all(content, predicate) ++ matches

          _ ->
            # Text nodes have no children
            matches
        end
    end)
  end

  @doc """
  Finds the first node in an AST that matches a predicate function.

  ## Examples

      iex> AST.find_first([
      ...>   {"h1", %{}, ["Title"], %{}},
      ...>   {"p", %{}, ["Paragraph"], %{}}
      ...> ], fn
      ...>   {"p", _, _, _} -> true
      ...>   _ -> false
      ...> end)
      {"p", %{}, ["Paragraph"], %{}}
  """
  @spec find_first(t(), (ast_node() -> boolean())) :: ast_node() | nil
  def find_first(ast, predicate)
      when is_list(ast) and is_function(predicate, 1) do
    Enum.find_value(ast, fn node ->
      # Check if the current node matches
      if predicate.(node) do
        node
      else
        # Otherwise, recursively check children if applicable
        case node do
          {_tag, _attrs, content, _meta} when is_list(content) ->
            # For elements, check children
            find_first(content, predicate)

          {:component, _type, _attrs, content, _meta} when is_list(content) ->
            # For components, check children
            find_first(content, predicate)

          _ ->
            # Text nodes have no children
            nil
        end
      end
    end)
  end

  @doc """
  Extracts plain text content from an AST by concatenating all text nodes.

  This is useful for generating text-only versions of content for SEO,
  previews, or search indexing.

  ## Examples

      iex> AST.text_content([
      ...>   {"h1", %{}, ["Hello ", "World"], %{}},
      ...>   {"p", %{}, ["This is a ", {"em", %{}, ["paragraph"], %{}}], %{}}
      ...> ])
      "Hello World This is a paragraph"
  """
  @spec text_content(t()) :: String.t()
  def text_content(ast) when is_list(ast) do
    Enum.map_join(ast, " ", &extract_text/1)
    |> String.trim()
  end

  # Private helper to extract text from a node
  defp extract_text(node) do
    case node do
      text when is_binary(text) ->
        text

      {_tag, _attrs, content, _meta} when is_list(content) ->
        text_content(content)

      {:component, _type, _attrs, content, _meta} when is_list(content) ->
        text_content(content)

      _ ->
        ""
    end
  end
end
