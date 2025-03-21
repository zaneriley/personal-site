defmodule Portfolio.Content.MarkdownRendering.Renderer do
  @moduledoc """
  Handles the rendering and caching of markdown content to HTML.

  This module provides functions to parse markdown content, transform it into
  a schema-specific AST, render it as HTML, and cache the results. It supports
  different content types and provides options for customizing the rendering process.

  ## Examples

      iex> markdown = "# Hello, world!"
      iex> Renderer.render_and_cache(markdown, :note, "note_1")
      {:ok, "<h1>Hello, world!</h1>"}
  """
  alias Portfolio.Content.Types

  alias Portfolio.Content.MarkdownRendering.{
    MarkdownParser,
    ComponentBuilder,
    Pipeline
  }

  alias Portfolio.Content.MarkdownRendering.Pipeline.{Stage, Stages}
  alias Portfolio.Cache
  require Logger

  @type content_type :: Types.content_type()
  @type render_option ::
          {:include_frontmatter, boolean()}
          | {:force_refresh, boolean()}
          | {:return_ast, boolean()}
  @type render_options :: [render_option()]
  @type pipeline_option :: {:content_type, content_type()} | {:metadata, map()}
  @type pipeline_options :: [pipeline_option()]
  @cache_ttl :timer.hours(24 * 30)

  @doc """
  Renders markdown content directly to AST.

  This function parses the markdown content and transforms it into an AST without
  converting to HTML or caching the result.

  ## Parameters

    * `markdown` - The markdown content to render.
    * `opts` - Optional keyword list of options.

  ## Options

    * `:content_type` - The type of content being rendered.
    * `:metadata` - Additional metadata for pipeline processing.

  ## Returns

    * `{:ok, ast}` - The rendered AST.
    * `{:error, reason}` - An error occurred during rendering.
  """
  @spec render(String.t(), pipeline_options()) ::
          {:ok, list()} | {:error, any()}
  def render(markdown, opts \\ []) do
    with {:ok, custom_ast} <- MarkdownParser.parse(markdown),
         {:ok, processed_ast} <- process_ast_through_pipeline(custom_ast, opts) do
      {:ok, processed_ast}
    else
      {:error, reason} ->
        Logger.error("Error rendering AST: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Renders markdown content to AST and caches both the AST and HTML.

  ## Parameters

    * `markdown` - The markdown content to render.
    * `content_type` - The type of content being rendered.
    * `content_id` - A unique identifier for the content (used for caching).
    * `opts` - A keyword list of options.

  ## Options

    * `:force_refresh` - Force a re-render even if cached content exists.
    * `:include_frontmatter` - Include frontmatter in the rendered output.
    * `:return_ast` - Return the AST instead of HTML (default: false).

  ## Returns

    * `{:ok, html_or_ast}` - The rendered content (HTML string or AST).
    * `{:error, reason}` - An error occurred during rendering.
  """
  @spec render_and_cache(
          String.t(),
          Types.content_type(),
          String.t(),
          render_options()
        ) ::
          {:ok, String.t() | list()} | {:error, atom()}
  def render_and_cache(content, content_type, content_id, opts \\ []) do
    html_cache_key = "compiled_content:#{content_id}"
    ast_cache_key = "ast:#{content_id}"
    force_refresh = Keyword.get(opts, :force_refresh, false)
    bypass_cache = Keyword.get(opts, :bypass_cache, false)
    return_ast = Keyword.get(opts, :return_ast, false)
    # Only render markdown fields by default
    is_markdown = Keyword.get(opts, :is_markdown, true)

    Logger.debug(
      "Rendering and caching for content_id: #{content_id}, content_type: #{content_type}"
    )

    handle_render_and_cache(
      content,
      content_type,
      content_id,
      %{
        html_cache_key: html_cache_key,
        ast_cache_key: ast_cache_key,
        cache_status: {
          Cache.exists?(html_cache_key, bypass_cache: bypass_cache),
          Cache.exists?(ast_cache_key, bypass_cache: bypass_cache)
        },
        force_refresh: force_refresh,
        bypass_cache: bypass_cache,
        return_ast: return_ast,
        is_markdown: is_markdown,
        opts: opts
      }
    )
  end

  # Private helper function to handle different cache scenarios
  defp handle_render_and_cache(content, content_type, content_id, context) do
    %{
      html_cache_key: html_cache_key,
      ast_cache_key: ast_cache_key,
      cache_status: cache_status,
      force_refresh: force_refresh,
      bypass_cache: bypass_cache,
      return_ast: return_ast,
      is_markdown: is_markdown,
      opts: opts
    } = context

    case {cache_status, force_refresh, bypass_cache, return_ast} do
      # Cache disabled
      {{:cache_disabled, _}, _, _, _} ->
        handle_cache_disabled(content, content_type, is_markdown, return_ast)

      # Cache bypassed
      {_, _, true, _} ->
        handle_cache_bypassed(content, content_type, is_markdown, return_ast)

      # HTML cache exists, AST not needed
      {{true, _}, false, false, false} ->
        handle_html_cache_exists(
          content,
          content_type,
          content_id,
          html_cache_key,
          opts,
          is_markdown
        )

      # AST cache exists, return AST
      {{_, true}, false, false, true} ->
        handle_ast_cache_exists(
          content,
          content_type,
          content_id,
          ast_cache_key,
          opts
        )

      # Need to generate both HTML and AST
      _ ->
        handle_cache_miss(
          content,
          content_type,
          content_id,
          opts,
          is_markdown,
          return_ast
        )
    end
  end

  # Handle case where cache is disabled
  defp handle_cache_disabled(content, content_type, is_markdown, return_ast) do
    Logger.debug("Cache is disabled. Rendering without caching")

    if return_ast do
      render(content, content_type: content_type)
    else
      do_render(content, content_type, is_markdown)
    end
  end

  # Handle case where cache is bypassed
  defp handle_cache_bypassed(content, content_type, is_markdown, return_ast) do
    Logger.debug("Cache bypassed")

    if return_ast do
      render(content, content_type: content_type)
    else
      do_render(content, content_type, is_markdown)
    end
  end

  # Handle case where HTML cache exists
  defp handle_html_cache_exists(
         content,
         content_type,
         content_id,
         html_cache_key,
         opts,
         is_markdown
       ) do
    Logger.debug("HTML cache exists for content_id: #{content_id}")

    case Cache.get(html_cache_key) do
      {:ok, cached_html} when is_binary(cached_html) ->
        Logger.debug("Returning cached HTML for content_id: #{content_id}")
        {:ok, cached_html}

      _ ->
        Logger.warning(
          "Cached HTML value is invalid for content_id: #{content_id}. Re-rendering."
        )

        do_render_and_cache(
          content,
          content_type,
          content_id,
          opts,
          is_markdown
        )
    end
  end

  # Handle case where AST cache exists
  defp handle_ast_cache_exists(
         content,
         content_type,
         content_id,
         ast_cache_key,
         opts
       ) do
    Logger.debug("AST cache exists for content_id: #{content_id}")

    case Cache.get(ast_cache_key) do
      {:ok, cached_ast} when is_list(cached_ast) ->
        Logger.debug("Returning cached AST for content_id: #{content_id}")
        {:ok, cached_ast}

      _ ->
        Logger.warning(
          "Cached AST value is invalid for content_id: #{content_id}. Re-rendering."
        )

        render_and_cache_ast(content, content_type, content_id, opts)
    end
  end

  # Handle case where cache doesn't exist or refresh is forced
  defp handle_cache_miss(
         content,
         content_type,
         content_id,
         opts,
         is_markdown,
         return_ast
       ) do
    Logger.debug(
      "Cache doesn't exist or refresh forced for content_id: #{content_id}. Rendering and caching."
    )

    if return_ast do
      render_and_cache_ast(content, content_type, content_id, opts)
    else
      do_render_and_cache(content, content_type, content_id, opts, is_markdown)
    end
  end

  @doc """
  Invalidates the cache for a specific content item.

  ## Parameters

    * `content_id` - The unique identifier for the content.

  ## Returns

    * `:ok` - The cache was successfully invalidated.
    * `{:error, reason}` - An error occurred during cache invalidation.
  """
  @spec invalidate_cache(String.t()) :: :ok | {:error, atom()}
  def invalidate_cache(content_id) do
    Logger.debug("Invalidating cache for content_id: #{content_id}")
    html_cache_key = "compiled_content:#{content_id}"
    ast_cache_key = "ast:#{content_id}"

    Cache.delete(html_cache_key)
    Cache.delete(ast_cache_key)
    :ok
  end

  # Helper for rendering and caching both HTML and AST
  @spec do_render_and_cache(
          String.t(),
          Types.content_type(),
          String.t(),
          render_options(),
          boolean()
        ) ::
          {:ok, String.t()} | {:error, atom()}
  defp do_render_and_cache(content, content_type, content_id, opts, is_markdown) do
    html_cache_key = "compiled_content:#{content_id}"

    case do_render(content, content_type, is_markdown) do
      {:ok, html} ->
        # Cache the rendered HTML
        {:ok, _} =
          Cache.put(
            html_cache_key,
            html,
            ttl: @cache_ttl
          )

        # Also generate and cache the AST
        if is_markdown do
          render_and_cache_ast(content, content_type, content_id, opts)
        end

        {:ok, html}

      {:error, reason} = error ->
        Logger.error(
          "Failed to render content for #{content_type} with ID: #{content_id}. Error: #{inspect(reason)}"
        )

        error
    end
  end

  # Helper for rendering and caching AST only
  @spec render_and_cache_ast(
          String.t(),
          Types.content_type(),
          String.t(),
          render_options()
        ) ::
          {:ok, list()} | {:error, any()}
  defp render_and_cache_ast(content, content_type, content_id, opts) do
    # Parse the markdown
    with {:ok, custom_ast} <- MarkdownParser.parse(content),
         # Process through pipeline with proper options
         {:ok, processed_ast} <-
           process_ast_through_pipeline(
             custom_ast,
             [content_type: content_type] ++ opts
           ) do
      # Cache the AST
      {:ok, _} =
        Cache.put(
          "ast:#{content_id}",
          processed_ast,
          ttl: @cache_ttl
        )

      # Return the AST
      {:ok, processed_ast}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Helper for pipeline building
  @spec build_pipeline(content_type(), keyword()) :: function()
  defp build_pipeline(_content_type, opts) do
    # Extract metadata from options
    metadata = Keyword.get(opts, :metadata, %{})

    # Create stages with properly wrapped options
    typography_stage = Stage.from_module(Stages.TypographyEnhancement, [])

    component_stage =
      Stage.from_module(Stages.ComponentResolution, ignore_missing: true)

    layout_stage =
      Stage.from_module(Stages.LayoutProcessing, metadata: metadata)

    # Build pipeline with all stages
    Pipeline.new([
      typography_stage,
      component_stage,
      layout_stage
    ])
  end

  # When rendering content that is not markdown
  defp do_render(content, _content_type, false) do
    {:ok, content}
  end

  # Render markdown content
  defp do_render("", _content_type, true) do
    # Return error for empty content
    {:error, :empty_content}
  end

  defp do_render(content, content_type, true) do
    with {:ok, custom_ast} <- MarkdownParser.parse(content),
         {:ok, processed_ast} <-
           process_ast_through_pipeline(custom_ast, content_type: content_type),
         {:ok, html} <-
           generate_html_from_ast(processed_ast, content_type) do
      {:ok, html}
    else
      {:error, reason} ->
        Logger.error("Error rendering HTML: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Process AST through pipeline
  defp process_ast_through_pipeline(schema_ast, opts) do
    content_type = Keyword.get(opts, :content_type, :note)

    # Get metadata from schema_ast's frontmatter, ensuring it's a map
    frontmatter_metadata =
      case Map.get(schema_ast, :frontmatter) do
        nil ->
          %{}

        metadata when is_map(metadata) ->
          metadata

        metadata when is_binary(metadata) ->
          # If we somehow got a string, parse it
          try do
            case :yamerl_constr.string(metadata) do
              [parsed] ->
                Enum.into(parsed, %{}, fn {k, v} -> {to_string(k), v} end)

              _ ->
                %{}
            end
          rescue
            _ -> %{}
          end

        _ ->
          %{}
      end

    # Get provided metadata, ensuring it's a map
    provided_metadata =
      case Keyword.get(opts, :metadata) do
        nil -> %{}
        metadata when is_map(metadata) -> metadata
        metadata when is_list(metadata) -> Enum.into(metadata, %{})
        _ -> %{}
      end

    # Merge the metadata, with provided_metadata taking precedence
    merged_metadata = Map.merge(frontmatter_metadata, provided_metadata)

    # Update the options with the merged metadata
    opts_with_metadata = Keyword.put(opts, :metadata, merged_metadata)

    # Build and execute the pipeline
    pipeline = build_pipeline(content_type, opts_with_metadata)
    Pipeline.process(pipeline, schema_ast.ast)
  end

  # Handle HTML generation from processed AST
  defp generate_html_from_ast(processed_ast, content_type) do
    case ComponentBuilder.render(%{ast: processed_ast},
           content_type: content_type
         ) do
      {:ok, component_ast} ->
        # Convert component AST to HTML string
        html = ComponentBuilder.to_html(component_ast, content_type)
        {:ok, html}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
