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
  alias Portfolio.Content.MarkdownRendering.{CustomParser, HTMLCompiler}
  alias Portfolio.Cache
  require Logger

  @type content_type :: Types.content_type()
  @type render_option ::
          {:include_frontmatter, boolean()} | {:force_refresh, boolean()}
  @type render_options :: [render_option()]
  @cache_ttl :timer.hours(24 * 30)

  @doc """
  Renders markdown to HTML and caches the result.

  ## Parameters

    * `markdown` - The markdown content to render.
    * `content_type` - The type of content being rendered.
    * `content_id` - A unique identifier for the content (used for caching).
    * `opts` - A keyword list of options.

  ## Options

    * `:force_refresh` - Force a re-render even if cached content exists.
    * `:include_frontmatter` - Include frontmatter in the rendered output.

  ## Returns

    * `{:ok, html}` - The rendered HTML content.
    * `{:error, reason}` - An error occurred during rendering.
  """
  @spec render_and_cache(
          String.t(),
          Types.content_type(),
          String.t(),
          render_options()
        ) ::
          {:ok, String.t()} | {:error, atom()}
  def render_and_cache(content, content_type, content_id, opts \\ []) do
    cache_key = "compiled_content:#{content_id}"
    force_refresh = Keyword.get(opts, :force_refresh, false)
    bypass_cache = Keyword.get(opts, :bypass_cache, false)
    # Only render markdown fields by default
    is_markdown = Keyword.get(opts, :is_markdown, true)

    Logger.debug(
      "Rendering and caching for content_id: #{content_id}, content_type: #{content_type}"
    )

    Logger.debug("Content: #{inspect(String.slice(content, 0, 50))}...")

    case Cache.exists?(cache_key, bypass_cache: bypass_cache) do
      :cache_disabled ->
        Logger.debug(
          "Cache is disabled. Rendering without caching for content_id: #{content_id}"
        )

        do_render(content, content_type, is_markdown)

      :cache_bypassed ->
        Logger.debug("Cache bypassed for content_id: #{content_id}")
        do_render(content, content_type, is_markdown)

      true when not (bypass_cache or force_refresh) ->
        Logger.debug("Cache exists for content_id: #{content_id}")

        case Cache.get(cache_key) do
          {:ok, cached_content} when is_binary(cached_content) ->
            Logger.debug(
              "Returning cached content for content_id: #{content_id}"
            )

            {:ok, cached_content}

          _ ->
            Logger.warning(
              "Cached value is invalid for content_id: #{content_id}. Re-rendering."
            )

            do_render_and_cache(
              content,
              content_type,
              cache_key,
              opts,
              is_markdown
            )
        end

      false ->
        Logger.debug(
          "Cache doesn't exist for content_id: #{content_id}. Rendering and caching."
        )

        do_render_and_cache(content, content_type, cache_key, opts, is_markdown)

      _ ->
        Logger.debug(
          "Unexpected cache state or refresh forced for content_id: #{content_id}. Rendering and caching."
        )

        do_render_and_cache(content, content_type, cache_key, opts, is_markdown)
    end
  end

  @doc """
  Invalidates the cache for a specific content item.

  ## Parameters

    * `content_id` - The unique identifier for the content.

  ## Returns

    * `:ok` - If the cache was successfully invalidated.
  """
  @spec invalidate_cache(String.t()) :: :ok
  def invalidate_cache(content_id) do
    cache_key = "compiled_content:#{content_id}"

    case Cache.delete(cache_key) do
      :cache_disabled ->
        Logger.debug(
          "Cache is disabled. No need to invalidate for content_id: #{content_id}"
        )

      :cache_bypassed ->
        Logger.debug(
          "Cache bypassed. No invalidation performed for content_id: #{content_id}"
        )

      {:ok, _} ->
        Logger.debug("Cache invalidated for content_id: #{content_id}")

      {:error, reason} ->
        Logger.error(
          "Failed to invalidate cache for content_id: #{content_id}. Reason: #{inspect(reason)}"
        )
    end

    :ok
  end

  # Private functions
  @spec do_render_and_cache(
          String.t(),
          Types.content_type(),
          String.t(),
          render_options(),
          boolean()
        ) ::
          {:ok, String.t()} | {:error, atom()}
  defp do_render_and_cache(markdown, content_type, cache_key, opts, is_markdown) do
    Logger.debug(
      "Rendering markdown for cache_key: #{cache_key}, content_type: #{content_type}"
    )

    case do_render(markdown, content_type, is_markdown) do
      {:ok, html} ->
        Logger.debug("Successfully rendered HTML for cache_key: #{cache_key}")

        case Cache.put(cache_key, html, ttl: @cache_ttl) do
          :cache_disabled ->
            Logger.debug(
              "Cache is disabled. Content rendered but not cached for cache_key: #{cache_key}"
            )

          :cache_bypassed ->
            Logger.debug(
              "Cache bypassed. Content rendered but not cached for cache_key: #{cache_key}"
            )

          {:ok, true} ->
            Logger.debug(
              "Content successfully cached for cache_key: #{cache_key}"
            )

          {:error, reason} ->
            Logger.warning(
              "Failed to cache content for cache_key: #{cache_key}. Reason: #{inspect(reason)}"
            )
        end

        {:ok, html}

      error ->
        error
    end
  end

  @spec do_render(String.t(), content_type(), boolean()) ::
          {:ok, String.t()} | {:error, atom()}
  defp do_render(content, content_type, is_markdown) do
    if is_markdown do
      case convert_markdown_to_html(content, content_type) do
        {:ok, html} when is_binary(html) and html != "" ->
          {:ok, html}

        {:ok, ""} ->
          Logger.warning("Rendered content is empty")
          {:error, :empty_content}

        error ->
          error
      end
    else
      {:ok, content}
    end
  end

  @spec convert_markdown_to_html(String.t(), content_type()) ::
          {:ok, String.t()} | {:error, atom()}
  defp convert_markdown_to_html(markdown, content_type) do
    Logger.debug(
      "Converting markdown to HTML for content_type: #{content_type}"
    )

    with {:ok, custom_ast} <- CustomParser.parse(markdown),
         {:ok, html} <-
           HTMLCompiler.render(custom_ast, content_type: content_type) do
      Logger.debug("Successfully converted markdown to HTML")
      {:ok, html}
    else
      {:error, reason} ->
        Logger.error("Error converting markdown to HTML: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
