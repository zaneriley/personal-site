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

  # Allowlists used by `render_to_safe/1`. Applied uniformly to bare HTML tag
  # nodes (raw HTML from Earmark) AND `:typography` nodes — the typography
  # transform preserves user-authored attrs on `<p>` / `<h*>` tags while
  # injecting its own `size`/`font`/`dropcap`, so user-injected `onclick`,
  # `style`, etc. would otherwise reach the rendered output via the typography
  # path. `:component` nodes still bypass this layer; their attrs are dispatched
  # to function components that own their own assigns contract.
  @allowed_tags MapSet.new(~w(
    p h1 h2 h3 h4 h5 h6 blockquote pre hr div
    section article aside header footer nav main
    figure figcaption
    a strong b em i u s code span small mark kbd abbr cite q sub sup time del ins br
    ul ol li dl dt dd
    table thead tbody tfoot tr td th caption colgroup col
    img picture source
  ))

  # `srcset` is deliberately excluded: it's URL-valued but contains a
  # comma-separated list of candidate URLs with descriptors, which would need
  # per-candidate parsing and scheme-checking. Until that lands, omit it.
  @allowed_attrs MapSet.new(~w(
    id class title lang dir role tabindex
    href target rel
    src sizes alt width height loading decoding
    datetime cite
    colspan rowspan scope headers
    start type
    size font dropcap locale
  ))

  @url_attrs MapSet.new(~w(href src))

  # Real allowlist of safe URL schemes (not a denylist). Anything outside this
  # set — `data:`, `file:`, `ftp:`, `javascript:`, `vbscript:`, `gopher:`,
  # `chrome:`, etc. — is rejected when it appears as an `href`/`src` value.
  @safe_url_schemes MapSet.new(~w(http https mailto tel))

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

  @doc """
  Renders an AST (or a binary body) to a `Phoenix.HTML.safe/0` value suitable for
  direct HEEx interpolation via `{render_to_safe(@assign)}`.

  Distinct from `render_html/1`, which returns `String.t()` and is consumed as
  `compiled_content` by the `Compiler.compile/2` path. This sibling returns
  `{:safe, iodata}` so templates can render the result without `raw/1` and
  without HEEx auto-escaping the tag markup we just built.

  Attribute values are escaped through `Phoenix.HTML.attributes_escape/1`.
  Text leaves are escaped through `Phoenix.HTML.html_escape/1`.
  """
  @spec render_to_safe(any()) :: Phoenix.HTML.safe()
  def render_to_safe(ast), do: {:safe, build_safe_iodata(ast)}

  defp build_safe_iodata(ast) when is_binary(ast) do
    {:safe, iodata} = Phoenix.HTML.html_escape(ast)
    iodata
  end

  defp build_safe_iodata(ast) when is_list(ast) do
    Enum.map(ast, &build_safe_iodata/1)
  end

  defp build_safe_iodata({:typography, tag, attrs, children, _meta}) do
    # Typography nodes are produced by the Typography transform, which
    # preserves user-authored attrs from raw `<p>` / `<h*>` markdown. Route
    # them through the same allowlist so `<p onclick="alert(1)">` from
    # markdown cannot reach the rendered output via the typography path.
    build_safe_tag(to_string(tag), safe_user_attrs(attrs), children)
  end

  defp build_safe_iodata({:component, type, attrs, children, _meta}) do
    case Portfolio.Content.Markdown.Component.Registry.lookup(type) do
      {:ok, {module, function}} ->
        # Sanitize URL-valued attrs (e.g. `src` from a markdown image with
        # `javascript:`). Then flatten attrs as top-level assigns so
        # `Phoenix.Component` functions can pattern-match expected names
        # (`:src`, `:alt`, …) directly, instead of crashing on `assigns.src`
        # when we'd passed them as `assigns.attrs[:src]`. Keep the wrapper
        # keys `:component`, `:attrs`, `:content` for any caller that still
        # destructures them.
        safe_attrs = safe_component_attrs(attrs)
        flat_attrs = Enum.into(safe_attrs, %{}, &flatten_attr_key/1)

        component_assigns =
          flat_attrs
          |> Map.put(:component, type)
          |> Map.put(:attrs, flat_attrs)
          |> Map.put(:content, render_html(children))

        module
        |> apply(function, [component_assigns])
        |> Phoenix.HTML.Safe.to_iodata()

      {:error, _reason} ->
        {:safe, type_iodata} = Phoenix.HTML.html_escape(to_string(type))

        [
          ~s(<div class="component-error">Component '),
          type_iodata,
          ~s(' not found</div>)
        ]
    end
  end

  defp build_safe_iodata({tag, attrs, children, _meta}) when is_binary(tag) do
    if MapSet.member?(@allowed_tags, tag) do
      build_safe_tag(tag, safe_user_attrs(attrs), children)
    else
      # Disallowed raw-HTML tag (script, iframe, style, object, …): drop the
      # wrapper and recurse so any nested text content is still escaped and
      # rendered. Prevents `<script>alert(1)</script>` markdown from emitting
      # an executable script tag inside a `{:safe, _}` payload.
      build_safe_iodata(children)
    end
  end

  defp build_safe_iodata(other) do
    {:safe, iodata} = Phoenix.HTML.html_escape(to_string(other))
    iodata
  end

  defp build_safe_tag(tag, attrs, children) do
    {:safe, attrs_iodata} = Phoenix.HTML.attributes_escape(attrs)
    ["<", tag, attrs_iodata, ">", build_safe_iodata(children), "</", tag, ">"]
  end

  defp safe_user_attrs(attrs) do
    attrs
    |> Enum.filter(&allowed_attr?/1)
    |> Enum.reject(&unsafe_url_attr?/1)
  end

  # Component attrs are not name-filtered (each component declares its own
  # `attr :foo` schema; Phoenix.Component validates per-call). We only
  # *neuter unsafe URL values* by replacing them with an empty string so the
  # component still receives every required key but cannot emit a working
  # `javascript:` link. Keeps the assigns shape the component expects.
  defp safe_component_attrs(attrs) do
    Enum.map(attrs, &sanitize_component_attr/1)
  end

  defp sanitize_component_attr({name, value}) when is_binary(value) do
    if MapSet.member?(@url_attrs, to_attr_name(name)) and not safe_url?(value) do
      {name, ""}
    else
      {name, value}
    end
  end

  defp sanitize_component_attr(pair), do: pair

  # Convert attr-list keys to atom-keyed map entries so that Phoenix.Component
  # `@src` style access works. String keys from Earmark (`"src"`, `"alt"`) get
  # converted to `:src` / `:alt` (via `String.to_existing_atom/1` to avoid the
  # atom-leak vector that applies to arbitrary author input — markdown
  # attribute names are bounded by the parser, so any name we'd see at this
  # point already exists). Unknown names fall back to the string key, which
  # Phoenix.Component will still accept as an assign though not as a typed
  # attr.
  defp flatten_attr_key({name, value}) when is_atom(name), do: {name, value}

  defp flatten_attr_key({name, value}) when is_binary(name) do
    {String.to_existing_atom(name), value}
  rescue
    ArgumentError -> {name, value}
  end

  defp allowed_attr?({name, _value}) do
    name = to_attr_name(name)

    MapSet.member?(@allowed_attrs, name) or
      String.starts_with?(name, "aria-") or
      String.starts_with?(name, "data-")
  end

  defp allowed_attr?(_), do: false

  defp unsafe_url_attr?({name, value}) when is_binary(value) do
    MapSet.member?(@url_attrs, to_attr_name(name)) and not safe_url?(value)
  end

  defp unsafe_url_attr?(_), do: false

  defp to_attr_name(name) when is_binary(name), do: name
  defp to_attr_name(name) when is_atom(name), do: Atom.to_string(name)

  # Allowlist of URL shapes accepted in `href`/`src`:
  #   - empty (preserves "no link" / refresh semantics)
  #   - relative path: starts with `/` (but not `//`, which is protocol-relative)
  #   - same-document fragment (`#…`) or query (`?…`)
  #   - any URL with one of @safe_url_schemes
  #   - bare relative path with no scheme (e.g. `foo`, `./foo`, `../foo`)
  defp safe_url?(value) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      trimmed == "" ->
        true

      String.starts_with?(trimmed, "//") ->
        false

      String.starts_with?(trimmed, "/") ->
        true

      String.starts_with?(trimmed, "#") ->
        true

      String.starts_with?(trimmed, "?") ->
        true

      has_scheme?(trimmed) ->
        MapSet.member?(@safe_url_schemes, scheme_of(trimmed))

      true ->
        true
    end
  end

  defp safe_url?(_), do: false

  defp has_scheme?(value), do: Regex.match?(~r/^[a-z][a-z0-9+\-.]*:/i, value)

  defp scheme_of(value) do
    case String.split(value, ":", parts: 2) do
      [scheme, _rest] -> String.downcase(scheme)
      _ -> ""
    end
  end
end
