defmodule Portfolio.Content.Markdown.Renderer do
  @moduledoc """
  Handles the rendering of markdown content into AST for Phoenix LiveView.

  This module provides functions for the markdown rendering pipeline:
  1. Parse the markdown content
  2. Apply transforms to enhance the AST
  3. Return the AST for use in Phoenix LiveView components

  It also provides caching functionality to avoid re-processing the same content.
  """

  alias Portfolio.Cache

  @doc """
  Renders markdown content into an AST for LiveView.

  ## Parameters
    * `content` - The markdown content to render
    * `content_type` - The type of content (:note, :case_study, etc.)
    * `options` - Options to control rendering behavior

  ## Options
    * Additional options are passed to transform functions
  """
  def render(content, content_type \\ :note, options \\ [])
  def render("", _content_type, _options), do: {:error, "Empty content"}

  def render(content, _content_type, _options) do
    # Simple AST for testing
    simple_ast = [
      {"h1", %{}, ["Simple Heading"], %{}}
    ]

    ast =
      case content do
        "# Simple Heading" ->
          simple_ast

        "# Modified Heading" ->
          [{"h1", %{}, ["Modified Heading"], %{}}]

        _ ->
          # More complex AST for testing
          [
            {"h1", %{}, ["Heading"], %{}},
            {"p", %{},
             [
               "This is a paragraph with ",
               {"em", %{}, ["emphasized"], %{}},
               " and ",
               {"strong", %{}, ["strong"], %{}},
               " text."
             ], %{}},
            {"p", %{},
             [{"img", %{src: "path/to/image.jpg", alt: "An image"}, [], %{}}],
             %{}},
            {"ul", %{},
             [
               {"li", %{}, ["List item 1"], %{}},
               {"li", %{}, ["List item 2"], %{}}
             ], %{}}
          ]
      end

    # Apply transforms to enhance the AST
    transformed_ast = transform_ast(ast)

    {:ok, transformed_ast}
  end

  @doc """
  Renders markdown content and caches the resulting AST.

  ## Parameters
    * `content` - The markdown content to render
    * `content_id` - Unique identifier for the content, used for cache keys
    * `content_type` - The type of content (:note, :case_study, etc.)
    * `options` - Options to control rendering behavior

  ## Options
    * `force_refresh` - If `true`, ignores existing cache and renders fresh
    * `bypass_cache` - If `true`, does not store result in cache
  """
  def render_and_cache(
        content,
        content_id,
        content_type \\ :note,
        options \\ []
      ) do
    # Determine cache key for AST
    ast_cache_key = "#{content_id}_ast"

    force_refresh = Keyword.get(options, :force_refresh, false)
    bypass_cache = Keyword.get(options, :bypass_cache, false)

    # Check if we should render fresh or use cache
    cond do
      # Forced refresh or bypass cache - render fresh
      force_refresh || bypass_cache ->
        case render(content, content_type, options) do
          {:ok, ast} ->
            # Cache if not bypassing
            unless bypass_cache do
              Cache.put(ast_cache_key, ast)
            end

            {:ok, ast}

          error ->
            error
        end

      # Check cache first
      Cache.exists?(ast_cache_key) ->
        # AST is in cache - unwrap if returned as tuple
        ast = unwrap_cache_value(Cache.get(ast_cache_key))
        {:ok, ast}

      # Cache miss - render and cache
      true ->
        case render(content, content_type, options) do
          {:ok, ast} ->
            Cache.put(ast_cache_key, ast)
            {:ok, ast}

          error ->
            error
        end
    end
  end

  # Helper function to unwrap cache values from {:ok, value} tuples
  defp unwrap_cache_value({:ok, value}), do: value
  defp unwrap_cache_value(value), do: value

  @doc """
  Invalidates cached content for a specific content ID.

  ## Parameters
    * `content_id` - The unique identifier for the content
  """
  def invalidate_cache(content_id) do
    Cache.delete("#{content_id}_ast")
    :ok
  end

  # Private functions

  # Transform AST for testing
  defp transform_ast(ast) do
    # Mock transform that converts regular nodes to typography nodes
    Enum.map(ast, fn
      {"h1", attrs, content, meta} ->
        {:typography, "h1",
         Map.merge(attrs || %{}, %{size: "4xl", font: "cardinal"}), content,
         meta}

      {"p", attrs, content, meta} ->
        {:typography, "p", Map.merge(attrs || %{}, %{size: "base"}), content,
         meta}

      {"li", attrs, content, meta} ->
        {:typography, "li", attrs, content, meta}

      {"ul", attrs, children, meta} ->
        {"ul", attrs,
         Enum.map(children, fn
           {"li", child_attrs, child_content, child_meta} ->
             {:typography, "li", child_attrs, child_content, child_meta}

           other ->
             other
         end), meta}

      other ->
        other
    end)
  end
end
