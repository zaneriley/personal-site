defmodule Portfolio.AstTestHelpers do
  @moduledoc """
  Utility functions for working with AST structures in tests.

  These helpers make it easier to write assertions against AST structures
  without being brittle to changes in the AST format or structure.
  """

  @doc """
  Extracts all text content from an AST structure, ignoring tags and attributes.

  This is useful for testing the semantic content of an AST without caring about
  the specific structure, tags, or attributes.

  ## Examples

      iex> extract_text("Simple string")
      "Simple string"

      iex> extract_text([{:typography, "p", %{}, ["Hello ", {"em", %{}, ["world"], %{}}], %{}}])
      "Hello world"

      iex> extract_text([{:component, :image, %{alt: "Alt text"}, [], %{}}])
      "Alt text"

      iex> extract_text(nil)
      ""
  """
  @spec extract_text(String.t() | list() | tuple() | map() | nil | any()) ::
          String.t()
  def extract_text(nil), do: ""
  def extract_text(value) when is_binary(value), do: value

  def extract_text(value) when is_list(value) do
    value
    |> extract_text_from_ast()
    |> Enum.join("")
  end

  def extract_text(value) do
    # Safely convert other values to string
    try do
      to_string(value)
    rescue
      Protocol.UndefinedError -> ""
    end
  end

  @doc """
  Recursively extracts text from an AST node or list of nodes.
  """
  @spec extract_text_from_ast(list() | tuple() | String.t() | nil | any()) :: [
          String.t()
        ]
  def extract_text_from_ast(nil), do: []

  def extract_text_from_ast(ast) when is_list(ast) do
    Enum.flat_map(ast, &extract_text_from_ast/1)
  end

  # Handle typography nodes
  def extract_text_from_ast({:typography, _tag, _attrs, children, _meta}) do
    extract_text_from_ast(children)
  end

  # Handle component nodes - extract from alt text if it's an image
  def extract_text_from_ast({:component, :image, attrs, _children, _meta}) do
    if Map.has_key?(attrs, :alt) do
      [attrs.alt]
    else
      []
    end
  end

  # Handle other component nodes
  def extract_text_from_ast({:component, _type, _attrs, children, _meta}) do
    extract_text_from_ast(children)
  end

  # Handle HTML element nodes
  def extract_text_from_ast({tag, _attrs, children, _meta})
      when is_binary(tag) do
    extract_text_from_ast(children)
  end

  # Handle plain text
  def extract_text_from_ast(text) when is_binary(text), do: [text]

  # Fallback for anything else
  def extract_text_from_ast(_), do: []
end
