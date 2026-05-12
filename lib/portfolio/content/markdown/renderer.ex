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
  alias Portfolio.Content.Markdown.Parser
  alias Portfolio.Content.Markdown.Pipeline
  alias Portfolio.Content.Markdown.Transforms

  require Logger

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

  def render(content, content_type, options) do
    # Parse the markdown content into an AST
    case Parser.parse(content) do
      {:ok, %{ast: raw_ast, frontmatter: frontmatter}} ->
        # Configure stages based on content type
        pipeline_opts =
          Keyword.merge(options,
            stages: [
              Transforms.Typography,
              Transforms.Component
            ],
            metadata: frontmatter,
            content_type: content_type
          )

        # Apply transforms using the pipeline
        Pipeline.process(raw_ast, pipeline_opts)

      {:error, reason} ->
        Logger.error("Failed to parse markdown content: #{inspect(reason)}")
        {:error, :parsing_failed}
    end
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
    ast_cache_key = "#{content_id}_ast"
    force_refresh = Keyword.get(options, :force_refresh, false)
    bypass_cache = Keyword.get(options, :bypass_cache, false)

    cond do
      # Case 1: Forced refresh, but don't bypass cache (render and store)
      force_refresh && !bypass_cache ->
        Logger.debug("Forcing refresh and caching for key: #{ast_cache_key}")

        case render(content, content_type, options) do
          {:ok, ast} ->
            # Overwrite cache
            Cache.put(ast_cache_key, ast)
            {:ok, ast}

          error ->
            error
        end

      # Case 2: Forced refresh OR bypass cache (render but don't store if bypassing)
      force_refresh || bypass_cache ->
        Logger.debug(
          "Rendering fresh (force_refresh: #{force_refresh}, bypass_cache: #{bypass_cache}) for key: #{ast_cache_key}"
        )

        # Simply render without interacting with the cache store action
        render(content, content_type, options)

      # Case 3: Standard behaviour (not forced, not bypassed)
      true ->
        Logger.debug("Standard cache check/render for key: #{ast_cache_key}")
        get_or_render_ast(ast_cache_key, content, content_type, options)
    end
  end

  # Helper for the "get from cache or render and cache on miss" logic
  defp get_or_render_ast(ast_cache_key, content, content_type, options) do
    if Cache.exists?(ast_cache_key) do
      # Cache hit
      Logger.debug("Cache hit for key: #{ast_cache_key}")
      {:ok, unwrap_cache_value(Cache.get(ast_cache_key))}
    else
      # Cache miss: render, cache, and return
      Logger.debug(
        "Cache miss for key: #{ast_cache_key}. Rendering and caching."
      )

      case render(content, content_type, options) do
        {:ok, ast} ->
          # Store the newly rendered AST
          Cache.put(ast_cache_key, ast)
          {:ok, ast}

        error ->
          Logger.error(
            "Render failed during cache miss for key: #{ast_cache_key}. Error: #{inspect(error)}"
          )

          # Propagate render error
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

  @doc """
  Processes a Markdown AST, recursively handling nested structures.
  This function preserves the AST structure while ensuring all nested nodes are processed.
  """
  def render_ast(ast) when is_binary(ast), do: ast

  def render_ast(ast) when is_list(ast) do
    Enum.map(ast, &render_ast/1)
  end

  def render_ast({:typography, tag, attrs, children, meta}) do
    processed_children = render_ast(children)
    {:typography, tag, attrs, processed_children, meta}
  end

  def render_ast({:component, type, attrs, children, meta}) do
    processed_children = render_ast(children)
    {:component, type, attrs, processed_children, meta}
  end

  def render_ast({tag, attrs, children, meta}) when is_binary(tag) do
    processed_children = render_ast(children)
    {tag, attrs, processed_children, meta}
  end

  # Catch-all for anything else (should ideally not be hit with well-formed AST)
  def render_ast(other), do: other

  @doc """
  Renders the AST to HTML strings for display in templates.

  This function should be used when you need to convert the AST to
  HTML for display in a template or when HTML is required.
  """
  def render_html(ast) when is_binary(ast), do: ast

  def render_html(ast) when is_list(ast) do
    Enum.map_join(ast, "", &render_html/1)
  end

  def render_html({:typography, tag, attrs, children, _meta}) do
    attrs_str = Enum.map_join(attrs, " ", fn {k, v} -> "#{k}=\"#{v}\"" end)

    attrs_html = if attrs_str == "", do: "", else: " " <> attrs_str

    "<#{tag}#{attrs_html}>#{render_html(children)}</#{tag}>"
  end

  def render_html({:component, type, attrs, children, _meta}) do
    # Look up the component in the registry
    case Portfolio.Content.Markdown.Component.Registry.lookup(type) do
      {:ok, {module, function}} ->
        # Convert keyword list to map for component
        attrs_map = Enum.into(attrs, %{})

        # Prepare assigns for the component function
        component_assigns = %{
          component: type,
          attrs: attrs_map,
          content: render_html(children)
        }

        # Render the component using apply/3
        apply(module, function, [component_assigns])

      {:error, _reason} ->
        # Fallback rendering if component not found
        "<div class=\"component-error\">Component '#{type}' not found</div>"
    end
  end

  def render_html({tag, attrs, children, _meta}) when is_binary(tag) do
    attrs_str = Enum.map_join(attrs, " ", fn {k, v} -> "#{k}=\"#{v}\"" end)

    attrs_html = if attrs_str == "", do: "", else: " " <> attrs_str

    "<#{tag}#{attrs_html}>#{render_html(children)}</#{tag}>"
  end

  def render_html(other), do: to_string(other)

  @doc """
  Preserves the AST structure without converting to HTML.
  This function simply returns the AST, making it suitable
  for passing to components that can handle AST nodes directly.
  """
  def preserve_ast(ast), do: ast
end
