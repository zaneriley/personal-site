defmodule Portfolio.Content.Markdown.Ast do
  @moduledoc """
  Provides utility functions for traversing and manipulating Markdown AST nodes.

  The Markdown processing pipeline (`Portfolio.Content.Markdown.Pipeline` and its
  transform stages) operates on an Abstract Syntax Tree (AST) represented primarily
  by nested tuples and lists. This module offers helper functions to work with this
  structure effectively.

  Key functions include:
  - `traverse/2`: Applies a function recursively to every node in the AST.
  - `find_nodes/2`: Locates all nodes within the AST that match a given predicate.
  - `transform/2`: Alias for `traverse/2`, emphasizing node transformation.

  These utilities are used internally by the `Parser` and various `Transform` stages
  to inspect and modify the AST during processing.
  """

  @doc """
  Traverses an AST and applies the given function to each node.

  The function should accept a node and return a transformed node.
  The traversal is depth-first, processing children after their parent node.

  ## Parameters

  * `ast` - The AST to traverse, as a list of nodes
  * `transform_fn` - Function that takes a node and returns a transformed node

  ## Returns

  A new AST with the transform function applied to all nodes

  ## Examples

      iex> ast = [{"div", [], [{"p", [], ["Text"], %{}}], %{}}]
      iex> transform_fn = fn {tag, attrs, children, meta} when is_binary(tag) ->
      ...>   {String.upcase(tag), attrs, children, meta}
      ...>   node -> node
      ...> end
      iex> Ast.traverse(ast, transform_fn)
      [{"DIV", [], [{"P", [], ["Text"], %{}}], %{}}]
  """
  def traverse(ast, transform_fn)
      when is_list(ast) and is_function(transform_fn, 1) do
    Enum.map(ast, &traverse_node(&1, transform_fn))
  end

  @doc """
  Finds all nodes in the AST that match the given predicate function.

  Traverses the AST depth-first and returns a list of all nodes for which
  the predicate function returns true.

  ## Parameters

  * `ast` - The AST to search, as a list of nodes
  * `predicate` - Function that takes a node and returns a boolean

  ## Returns

  A list of nodes that match the predicate

  ## Examples

      iex> ast = [{"div", [], [{"h1", [], ["Title"], %{}}, {"p", [], ["Text"], %{}}], %{}}]
      iex> Ast.find_nodes(ast, fn {tag, _, _, _} when tag == "h1" -> true; _ -> false end)
      [{"h1", [], ["Title"], %{}}]
  """
  def find_nodes(ast, predicate)
      when is_list(ast) and is_function(predicate, 1) do
    Enum.reduce(ast, [], fn node, acc ->
      acc ++ find_nodes_in_node(node, predicate)
    end)
  end

  @doc """
  Apply a transformation function to each node in the AST, recursively.

  The transform_fn receives each node and should return a transformed node.
  """
  def transform(ast, transform_fn)
      when is_list(ast) and is_function(transform_fn, 1) do
    Enum.map(ast, &traverse_node(&1, transform_fn))
  end

  # Private helpers

  defp traverse_node({tag, attrs, children, meta} = _node, transform_fn)
       when is_binary(tag) do
    # Apply transform to this node
    transformed_node = transform_fn.({tag, attrs, children, meta})

    # If the node wasn't completely replaced, recursively transform its children
    case transformed_node do
      {t, a, c, m} when is_list(c) ->
        {t, a, Enum.map(c, &traverse_node(&1, transform_fn)), m}

      _ ->
        transformed_node
    end
  end

  defp traverse_node(
         {:component, type, attrs, children, meta} = _node,
         transform_fn
       ) do
    # Apply transform to this node
    transformed_node = transform_fn.({:component, type, attrs, children, meta})

    # If the node wasn't completely replaced, recursively transform its children
    case transformed_node do
      {:component, t, a, c, m} when is_list(c) ->
        {:component, t, a, Enum.map(c, &traverse_node(&1, transform_fn)), m}

      _ ->
        transformed_node
    end
  end

  defp traverse_node(
         {:typography, type, attrs, children, meta} = _node,
         transform_fn
       ) do
    # Apply transform to this node
    transformed_node = transform_fn.({:typography, type, attrs, children, meta})

    # If the node wasn't completely replaced, recursively transform its children
    case transformed_node do
      {:typography, t, a, c, m} when is_list(c) ->
        {:typography, t, a, Enum.map(c, &traverse_node(&1, transform_fn)), m}

      _ ->
        transformed_node
    end
  end

  defp traverse_node(node, transform_fn) when is_binary(node) do
    # Text nodes are just passed through the transform function
    transform_fn.(node)
  end

  defp traverse_node(node, transform_fn) do
    # Any other node type just gets transformed
    transform_fn.(node)
  end

  defp find_nodes_in_node(node, predicate) do
    # First check if this node matches
    matches = if predicate.(node), do: [node], else: []

    # Then recursively check children based on node type
    children_matches =
      case node do
        {_, _, children, _} when is_list(children) ->
          find_nodes(children, predicate)

        {:component, _, _, children, _} when is_list(children) ->
          find_nodes(children, predicate)

        {:typography, _, _, children, _} when is_list(children) ->
          find_nodes(children, predicate)

        _ ->
          []
      end

    matches ++ children_matches
  end
end
