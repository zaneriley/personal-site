defmodule Portfolio.Content.Entry.AstSerialization do
  @moduledoc """
  Handles serialization and deserialization of Abstract Syntax Tree (AST) nodes.

  This module converts between the in-memory AST representation (tuples, lists)
  and a format suitable for storage in the database (maps, primitive types).

  The primary use case is to prepare AST structures from the Markdown rendering
  pipeline for persistence in Ecto schemas and later restore them for use
  in rendering components.
  """

  @type ast_node :: tuple() | String.t() | [ast_node()]
  @type serialized_node :: map() | String.t() | [serialized_node()]

  @doc """
  Converts an AST list into a serializable format.

  Takes an AST represented as a list of nodes (tuples, strings, or nested lists)
  and converts it to a format that can be safely serialized to JSON for storage.

  ## Parameters
    - ast: A list of AST nodes

  ## Returns
    - A list of serialized nodes (maps and primitive values)
  """
  @spec serialize_ast(list(ast_node())) :: list(serialized_node())
  def serialize_ast(ast) when is_list(ast) do
    Enum.map(ast, &serialize_ast_node/1)
  end

  @doc """
  Converts a single AST node into a serializable format.

  ## Parameters
    - node: An AST node (tuple, string, or nested list)

  ## Returns
    - A serialized representation of the node
  """
  @spec serialize_ast_node(ast_node()) :: serialized_node()
  def serialize_ast_node({tag, attrs, content, meta}) when is_binary(tag) do
    %{
      type: "element",
      tag: tag,
      attrs: serialize_attrs(attrs),
      content: serialize_ast(content),
      meta: meta
    }
  end

  def serialize_ast_node({:typography, tag, attrs, content, meta}) do
    %{
      type: "typography",
      tag: tag,
      attrs: serialize_attrs(attrs),
      content: serialize_ast(content),
      meta: meta
    }
  end

  def serialize_ast_node({:component, type, attrs, content, meta}) do
    %{
      type: "component",
      component_type: type,
      attrs: serialize_attrs(attrs),
      content: serialize_ast(content),
      meta: meta
    }
  end

  def serialize_ast_node(content) when is_binary(content) do
    %{type: "text", content: content}
  end

  def serialize_ast_node(other) do
    # For any other type, convert to string representation
    %{type: "unknown", content: inspect(other)}
  end

  @doc """
  Converts attributes to a serializable format.

  ## Parameters
    - attrs: Attributes as a map, list of key-value tuples, or nil

  ## Returns
    - A serialized map of attributes
  """
  @spec serialize_attrs(map() | list() | nil) :: map()
  def serialize_attrs(attrs) when is_map(attrs) do
    Map.new(attrs, fn {k, v} -> {to_string(k), v} end)
  end

  def serialize_attrs(nil), do: %{}
  def serialize_attrs([]), do: %{}

  def serialize_attrs(attrs) when is_list(attrs) do
    Enum.into(attrs, %{}, fn {k, v} -> {to_string(k), v} end)
  end

  # Catch-all clause to handle any other type of attributes
  def serialize_attrs(_), do: %{}

  @doc """
  Deserializes a list of serialized AST nodes back into their tuple representation.

  ## Parameters
    - ast: A list of serialized nodes

  ## Returns
    - A list of deserialized AST nodes
  """
  @spec deserialize_ast(list(serialized_node())) :: list(ast_node())
  def deserialize_ast(ast) when is_list(ast) do
    Enum.map(ast, &deserialize_ast_node/1)
  end

  @doc """
  Deserializes a single serialized node back into its AST representation.

  ## Parameters
    - node: A serialized node

  ## Returns
    - A deserialized AST node
  """
  @spec deserialize_ast_node(serialized_node()) :: ast_node()
  def deserialize_ast_node(%{type: "text", content: content})
      when is_binary(content) do
    content
  end

  def deserialize_ast_node(%{
        type: "element",
        tag: tag,
        attrs: attrs,
        content: content,
        meta: meta
      }) do
    {tag, deserialize_attrs(attrs), deserialize_ast(content), meta}
  end

  def deserialize_ast_node(%{
        type: "typography",
        tag: tag,
        attrs: attrs,
        content: content,
        meta: meta
      }) do
    {:typography, tag, deserialize_attrs(attrs), deserialize_ast(content), meta}
  end

  def deserialize_ast_node(%{
        type: "component",
        component_type: type,
        attrs: attrs,
        content: content,
        meta: meta
      }) do
    {:component, type, deserialize_attrs(attrs), deserialize_ast(content), meta}
  end

  # Handle string keys
  def deserialize_ast_node(%{"type" => "text", "content" => content})
      when is_binary(content) do
    content
  end

  def deserialize_ast_node(%{
        "type" => "element",
        "tag" => tag,
        "attrs" => attrs,
        "content" => content,
        "meta" => meta
      }) do
    {tag, deserialize_attrs(attrs), deserialize_ast(content), meta}
  end

  def deserialize_ast_node(%{
        "type" => "typography",
        "tag" => tag,
        "attrs" => attrs,
        "content" => content,
        "meta" => meta
      }) do
    {:typography, tag, deserialize_attrs(attrs), deserialize_ast(content), meta}
  end

  def deserialize_ast_node(%{
        "type" => "component",
        "component_type" => type,
        "attrs" => attrs,
        "content" => content,
        "meta" => meta
      }) do
    {:component, type, deserialize_attrs(attrs), deserialize_ast(content), meta}
  end

  def deserialize_ast_node(%{tuple_key: key, tuple_value: value})
      when is_binary(key) do
    {key, deserialize_ast_node(value)}
  end

  def deserialize_ast_node(%{"tuple_key" => key, "tuple_value" => value})
      when is_binary(key) do
    {key, deserialize_ast_node(value)}
  end

  def deserialize_ast_node(node) when is_binary(node), do: node
  def deserialize_ast_node(node) when is_list(node), do: deserialize_ast(node)

  # Catch-all for any other type of node
  def deserialize_ast_node(node), do: node

  @doc """
  Deserializes attributes from a map back into their original format.

  ## Parameters
    - attrs: A map of serialized attributes

  ## Returns
    - A map of deserialized attributes
  """
  @spec deserialize_attrs(map()) :: map()
  def deserialize_attrs(attrs) when is_map(attrs) do
    attrs
  end
end
