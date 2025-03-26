# AST Rendering Implementation Summary

## Problem Statement

The application was encountering issues with rendering markdown content in LiveView templates. The core issue stemmed from changes in the `Renderer` module, which was modified to return AST (Abstract Syntax Tree) nodes instead of HTML strings. This change broke various parts of the codebase that expected HTML strings.

## Key Changes Implemented

### 1. Added `render_html` function to the Renderer module

We added a new function to convert AST to HTML strings, maintaining backward compatibility:

```elixir
# lib/portfolio/content/markdown/renderer.ex
def render_html(ast) when is_binary(ast), do: ast

def render_html(ast) when is_list(ast) do
  ast
  |> Enum.map(&render_html/1)
  |> Enum.join("")
end

def render_html({:typography, tag, attrs, children, _meta}) do
  attrs_str = attrs
              |> Enum.map(fn {k, v} -> "#{k}=\"#{v}\"" end)
              |> Enum.join(" ")
  
  attrs_html = if attrs_str == "", do: "", else: " " <> attrs_str
  
  "<#{tag}#{attrs_html}>#{render_html(children)}</#{tag}>"
end

def render_html({:component, type, attrs, children, _meta}) do
  # Look up the component in the registry
  case Portfolio.Content.Markdown.Component.Registry.lookup(type) do
    {:ok, module} ->
      # Convert keyword list to map for component
      attrs_map = Enum.into(attrs, %{})
      
      # Render the component
      module.render(%{
        component: type,
        attrs: attrs_map,
        content: render_html(children)
      })
    
    {:error, _reason} ->
      # Fallback rendering if component not found
      "<div class=\"component-error\">Component '#{type}' not found</div>"
  end
end
```

### 2. Updated LiveView templates to use `render_html`

The case study LiveView was updated to import and use `render_html` instead of `render_ast`:

```elixir
# lib/portfolio_web/live/case_study_live/show.ex
import Portfolio.Content.Markdown.Renderer, only: [render_ast: 1, render_html: 1]
```

```heex
<!-- lib/portfolio_web/live/case_study_live/show.html.heex -->
<div class="space-y-md drop-cap">
  <%= if @translations["content"] do %>
    <%= render_html(@translations["content"]) %>
  <% else %>
    <%= if @ast_content do %>
      <%= render_html(@ast_content) %>
    <% else %>
      <!-- Error handling content -->
    <% end %>
  <% end %>
</div>
```

### 3. Fixed test cases to handle AST instead of HTML strings

Tests were updated to expect AST lists instead of strings:

```elixir
# test/portfolio/content/content_test.exs
test "get!/2 returns the content item with given id" do
  note = ContentFixtures.note_fixture()
  retrieved_note = Content.get!("note", note.id)
  assert retrieved_note.id == note.id
  assert retrieved_note.title == note.title
  assert retrieved_note.content == note.content
  assert is_list(retrieved_note.compiled_content)
end
```

### 4. Added AST extraction helper for tests

Created a helper function to extract text from AST nodes in tests:

```elixir
# Helper function to extract text from AST
defp extract_text_from_ast(nil), do: ""

defp extract_text_from_ast(ast) when is_list(ast) do
  ast
  |> Enum.map(&extract_text_from_ast/1)
  |> Enum.join("")
end

defp extract_text_from_ast({_tag, _attrs, children, _meta}) do
  extract_text_from_ast(children)
end

defp extract_text_from_ast({:typography, _tag, _attrs, children, _meta}) do
  extract_text_from_ast(children)
end

defp extract_text_from_ast({:component, _type, _attrs, children, _meta}) do
  extract_text_from_ast(children)
end

defp extract_text_from_ast(text) when is_binary(text), do: text
defp extract_text_from_ast(_), do: ""
```

## Current Issues

There are still a few tests failing:

1. Some tests still expect the `compiled_content` field to be a binary string but it's now an AST list.

2. The renderer test has a specific test case that expects components to have map-based attributes, but our implementation now uses keyword lists.

3. Case study LiveView tests fail with `ArgumentError: lists in Phoenix.HTML and templates may only contain integers representing bytes, binaries or other lists`, indicating that some templates are still trying to render raw AST.

## Next Steps

1. Complete the transition of all test cases to handle AST consistently (is_list checks)

2. Review the component rendering in tests to ensure we're consistently handling attributes as keyword lists

3. Make sure all templates use `render_html` instead of passing raw AST to the template engine

4. Add more documentation about the AST format to help developers understand the expected data structure
---
 16 │      PortfolioWeb.LiveHelpers.setup_common_assigns(socket, _params, session)}
    │                               ~
    │
    └─ lib/portfolio_web/live/case_study_live/show.ex:16:31: PortfolioWeb.CaseStudyLive.Show.on_mount/4

    warning: Portfolio.TestComponents.ensure_essential_components_registered/0 is undefined (module Portfolio.TestComponents is not available or is yet to be defined)
    │
 42 │     Portfolio.TestComponents.ensure_essential_components_registered()
    │                              ~
    │
    └─ test/support/conn_case.ex:42:30: PortfolioWeb.ConnCase.__ex_unit_setup_0/1

     warning: variable "name" is unused (if the variable is not meant to be used, prefix it with an underscore)
     │
 176 │                   <%= for {font, name} <- [
     │                                  ~
     │
     └─ lib/portfolio_web/live/kitchen_sink_live.ex:176:34: PortfolioWeb.KitchenSinkLive.render/1

    warning: unused import PortfolioWeb.Gettext
    │
  7 │   import PortfolioWeb.Gettext
    │   ~
    │
    └─ lib/portfolio_web/components/portfolio_items_list.ex:7:3

     warning: variable "assigns_dropcap" is unused (if the variable is not meant to be used, prefix it with an underscore)
     │
 110 │     assigns_dropcap = Map.get(assigns, :dropcap, false)
     │     ~~~~~~~~~~~~~~~
     │
     └─ lib/portfolio_web/components/typography_helpers.ex:110:5: PortfolioWeb.Components.TypographyHelpers.build_class_names/2

     warning: module attribute @doc was set but no definition follows it
     │
 216 │   @doc """
     │   ~~~~~~~~
     │
     └─ lib/portfolio/content/markdown/renderer.ex:216: Portfolio.Content.Markdown.Renderer (module)

    warning: module attribute @default_host was set but never used
    │
 24 │   @default_host "localhost"
    │   ~~~~~~~~~~~~~~~~~~~~~~~~~
    │
    └─ lib/portfolio_web/plugs/csp_header.ex:24: PortfolioWeb.Plugs.CSPHeader (module)

     warning: default values for the optional arguments in extract_text_from_ast/2 are never used
     │
 195 │   defp extract_text_from_ast(ast, opts \\ [])
     │        ~
     │
     └─ lib/portfolio/content/utils/metadata_calculator.ex:195:8: Portfolio.Content.Utils.MetadataCalculator (module)

    warning: variable "conn" is unused (there is a variable with the same name in the context, use the pin operator (^) to match on it or prefix this variable with underscore if it is not meant to be used)
    │
 90 │             conn =
    │             ~
    │
    └─ lib/portfolio_web/plugs/locale_redirection.ex:90:13: PortfolioWeb.Plugs.LocaleRedirection.handle_locale/4

    warning: variable "url" is unused (if the variable is not meant to be used, prefix it with an underscore)
    │
 38 │   defp apply_action(socket, :edit, %{"url" => url}) do
    │                                               ~~~
    │
    └─ lib/portfolio_web/live/case_study_live/index.ex:38:47: PortfolioWeb.CaseStudyLive.Index.apply_action/3

    warning: got "@impl true" for function on_mount/4 but no behaviour specifies such callback. The known callbacks are:

      * Phoenix.LiveView.handle_async/3 (function)
      * Phoenix.LiveView.handle_call/3 (function)
      * Phoenix.LiveView.handle_cast/2 (function)
      * Phoenix.LiveView.handle_event/3 (function)
      * Phoenix.LiveView.handle_info/2 (function)
      * Phoenix.LiveView.handle_params/3 (function)
      * Phoenix.LiveView.mount/3 (function)
      * Phoenix.LiveView.render/1 (function)
      * Phoenix.LiveView.terminate/2 (function)

    │
 11 │   def on_mount(:default, params, session, socket) do
    │   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    │
    └─ lib/portfolio_web/live/case_study_live/index.ex:11: PortfolioWeb.CaseStudyLive.Index (module)

    warning: struct Portfolio.Content.ContentTypeMismatchError is undefined (module Portfolio.Content.ContentTypeMismatchError is not available or is yet to be defined)
    │
 88 │       e in [
    │         ~
    │
    └─ lib/portfolio_web/live/case_study_live/index.ex:88:9: PortfolioWeb.CaseStudyLive.Index.handle_event/3

    warning: variable "all_fields" is unused (if the variable is not meant to be used, prefix it with an underscore)
    │
 41 │     all_fields = schema.__schema__(:fields)
    │     ~~~~~~~~~~
    │
    └─ lib/portfolio/content/translatable_fields.ex:41:5: Portfolio.Content.TranslatableFields.translatable_fields/1

    warning: unused alias Safe
    │
 73 │   alias Phoenix.HTML.Safe
    │   ~
    │
    └─ lib/portfolio_web/components/typography.ex:73:3

    warning: got "@impl true" for function on_mount/4 but no behaviour specifies such callback. The known callbacks are:

      * Phoenix.LiveView.handle_async/3 (function)
      * Phoenix.LiveView.handle_call/3 (function)
      * Phoenix.LiveView.handle_cast/2 (function)
      * Phoenix.LiveView.handle_event/3 (function)
      * Phoenix.LiveView.handle_info/2 (function)
      * Phoenix.LiveView.handle_params/3 (function)
      * Phoenix.LiveView.mount/3 (function)
      * Phoenix.LiveView.render/1 (function)
      * Phoenix.LiveView.terminate/2 (function)

    │
 10 │   def on_mount(:default, params, session, socket) do
    │   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    │
    └─ lib/portfolio_web/live/home_live.ex:10: PortfolioWeb.HomeLive (module)

    warning: got "@impl true" for function page_description/1 but no behaviour specifies such callback. The known callbacks are:

      * Phoenix.LiveView.handle_async/3 (function)
      * Phoenix.LiveView.handle_call/3 (function)
      * Phoenix.LiveView.handle_cast/2 (function)
      * Phoenix.LiveView.handle_event/3 (function)
      * Phoenix.LiveView.handle_info/2 (function)
      * Phoenix.LiveView.handle_params/3 (function)
      * Phoenix.LiveView.mount/3 (function)
      * Phoenix.LiveView.render/1 (function)
      * Phoenix.LiveView.terminate/2 (function)

    │
 21 │   def page_description(_assigns) do
    │   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    │
    └─ lib/portfolio_web/live/home_live.ex:21: PortfolioWeb.HomeLive (module)

    warning: got "@impl true" for function page_title/1 but no behaviour specifies such callback. The known callbacks are:

      * Phoenix.LiveView.handle_async/3 (function)
      * Phoenix.LiveView.handle_call/3 (function)
      * Phoenix.LiveView.handle_cast/2 (function)
      * Phoenix.LiveView.handle_event/3 (function)
      * Phoenix.LiveView.handle_info/2 (function)
      * Phoenix.LiveView.handle_params/3 (function)
      * Phoenix.LiveView.mount/3 (function)
      * Phoenix.LiveView.render/1 (function)
      * Phoenix.LiveView.terminate/2 (function)

    │
 16 │   def page_title(_assigns) do
    │   ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    │
    └─ lib/portfolio_web/live/home_live.ex:16: PortfolioWeb.HomeLive (module)

Running ExUnit with seed: 466725, max_cases: 8

.......    warning: variable "attrs" is unused (if the variable is not meant to be used, prefix it with an underscore)
    │
 54 │       {:ok, content_type, attrs} = Reader.read_markdown_file(path)
    │                           ~~~~~
    │
    └─ test/portfolio/content/file_management/reader_test.exs:54:27: Portfolio.Content.FileManagement.ReaderTest."test read_markdown_file/1 handles frontmatter with various data types"/1

    warning: variable "content_type" is unused (if the variable is not meant to be used, prefix it with an underscore)
    │
 54 │       {:ok, content_type, attrs} = Reader.read_markdown_file(path)
    │             ~~~~~~~~~~~~
    │
    └─ test/portfolio/content/file_management/reader_test.exs:54:13: Portfolio.Content.FileManagement.ReaderTest."test read_markdown_file/1 handles frontmatter with various data types"/1

...    warning: module attribute @reading_speed_native_en_code was set but never used
    │
 11 │   @reading_speed_native_en_code 50.0
    │   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    │
    └─ test/portfolio/content/utils/metadata_calculator_test.exs:11: Portfolio.Content.Utils.MetadataCalculatorTest (module)

    warning: unused import PortfolioWeb.Gettext
    │
  4 │   import PortfolioWeb.Gettext
    │   ~
    │
    └─ test/portfolio_web/components/theme_switcher_test.exs:4:3

    warning: function typeof/1 is unused
    │
 11 │   defp typeof(term) do
    │        ~
    │
    └─ test/portfolio/content/remote/git_repo_syncer_test.exs:11:8: Portfolio.Content.FileManagement.GitRepoSyncerTest (module)

...............    warning: module attribute @malformed_file_path was set but never used
    │
  9 │   @malformed_file_path "test/support/fixtures/case-study/testing-case-study-malformed/en.md"
    │   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    │
    └─ test/portfolio/content/file_management/watcher_test.exs:9: Portfolio.Content.FileManagement.WatcherTest (module)

.......    warning: variable "show_live" is unused (if the variable is not meant to be used, prefix it with an underscore)
    │
 57 │       {:ok, show_live, html} =
    │             ~~~~~~~~~
    │
    └─ test/portfolio_web/live/case_study_live_show_test.exs:57:13: PortfolioWeb.CaseStudyLive.ShowTest."test Case Study Show displays Japanese translation when locale is set to ja"/1

    warning: variable "valid_repo_url" is unused (if the variable is not meant to be used, prefix it with an underscore)
    │
 31 │     valid_repo_url: valid_repo_url,
    │                     ~~~~~~~~~~~~~~
    │
    └─ test/portfolio/content/remote/remote_update_trigger_test.exs:31:21: Portfolio.Content.Remote.RemoteUpdateTriggerTest."test trigger_update with invalid repository URL"/1

    warning: variable "local_path" is unused (if the variable is not meant to be used, prefix it with an underscore)
    │
 69 │     local_path: local_path
    │                 ~~~~~~~~~~
    │
    └─ test/portfolio/content/remote/remote_update_trigger_test.exs:69:17: Portfolio.Content.Remote.RemoteUpdateTriggerTest."test trigger_update with no changes in the repository"/1

......     warning: variable "content" is unused (if the variable is not meant to be used, prefix it with an underscore)
     │
 192 │       assert {:ok, content, translations, ast_result} =
     │                    ~~~~~~~
     │
     └─ test/portfolio/content/managers/translation_manager_test.exs:192:20: Portfolio.Content.TranslationTest."test translation functionality upsert_from_file updates existing content and Japanese translations"/1

....14:43:50.843 [error] Pipeline halted at stage Portfolio.Content.Markdown.PipelineTest.ErrorStage: "Error in pipeline stage"
......    warning: unused import Phoenix.Component
    │
  3 │   import Phoenix.Component
    │   ~
    │
    └─ test/portfolio_web/components/image_test.exs:3:3

.........14:43:51.422 [warning] Component 'image' already registered with Portfolio.TestComponents.Image
.14:43:51.631 [warning] Component 'image' already registered with Portfolio.TestComponents.Image
.14:43:51.633 [warning] Component 'image' already registered with Portfolio.TestComponents.Image
.14:43:51.635 [warning] Component 'image' already registered with Portfolio.TestComponents.Image
.14:43:51.649 [warning] Component 'image' already registered with Portfolio.TestComponents.Image
.14:43:51.650 [warning] Component 'image' already registered with Portfolio.TestComponents.Image
14:43:51.652 [warning] Component 'image' already registered with Portfolio.TestComponents.Image
.14:43:51.653 [warning] Component 'image' already registered with Portfolio.TestComponents.Image
.14:43:51.654 [warning] Component 'image' already registered with Portfolio.TestComponents.Image
..14:43:51.680 [warning] Component 'image' already registered with Portfolio.TestComponents.Image
.14:43:51.681 [warning] Component 'image' already registered with Portfolio.TestComponents.Image
.14:43:51.685 [warning] Component 'image' already registered with Portfolio.TestComponents.Image
.................14:43:53.162 [warning] Error processing webhook: Invalid or unsupported event type
.14:43:53.266 [warning] Error processing webhook: Invalid or unsupported event type
..

  1) test content retrieval get!/2 returns the content item with given id (Portfolio.Content.ContentTest)
     test/portfolio/content/content_test.exs:10
     Expected truthy, got false
     code: assert is_binary(retrieved_note.compiled_content)
     arguments:

         # 1
         [
           {:typography, "p", %{size: "md", dropcap: true},
            ["Content for note 1028 with insightful analysis and detailed information."], %{}}
         ]

     stacktrace:
       test/portfolio/content/content_test.exs:16: (test)

14:43:53.737 [error] Invalid content type provided: "invalid_type"
.

  2) test content retrieval get!/2 returns the content item with given url (Portfolio.Content.ContentTest)
     test/portfolio/content/content_test.exs:19
     Expected truthy, got false
     code: assert is_binary(retrieved_note.compiled_content)
     arguments:

         # 1
         [
           {:typography, "p", %{size: "md", dropcap: true},
            ["Content for note 1028 with insightful analysis and detailed information."], %{}}
         ]

     stacktrace:
       test/portfolio/content/content_test.exs:25: (test)

.

  3) test content update update/3 with invalid data returns error changeset (Portfolio.Content.ContentTest)
     test/portfolio/content/content_test.exs:80
     Expected truthy, got false
     code: assert is_binary(updated_note.compiled_content)
     arguments:

         # 1
         [
           {:typography, "p", %{size: "md", dropcap: true},
            ["Content for note 1028 with insightful analysis and detailed information."], %{}}
         ]

     stacktrace:
       test/portfolio/content/content_test.exs:91: (test)

14:43:54.220 [warning] Creating/updating translations for unsupported locale: fr
.14:43:54.352 [error] No schema found for type: "invalid_type"
.14:43:54.464 [warning] Creating/updating translations for unsupported locale: fr
..14:43:54.689 [error] No schema found for type: "invalid_type"
14:43:54.689 [error] Invalid content type: "invalid_type"
........14:43:55.724 [error] No schema found for type: "invalid"
....14:43:56.184 [error] Failed to extract locale from file path: invalid/path/example.md
..........
=== DEBUG DB Translations after update ===
Value: %{
  "content" => "更新されたコンテンツ",
  "file_path" => "ja translation for file_path",
  "introduction" => "ja translation for introduction",
  "locale" => "ja translation for locale",
  "read_time" => "ja translation for read_time",
  "title" => "更新されたタイトル",
  "url" => "ja translation for url",
  "word_count" => "ja translation for word_count"
}
=== END DEBUG DB Translations after update ===

.
=== DEBUG Translations from get_with_translations ===
Value: %{
  "content" => [
    {:typography, "p", %{size: "md", dropcap: true},
     ["翻訳されたコンテンツ"], %{}}
  ],
  "title" => "翻訳されたタイトル"
}
=== END DEBUG Translations from get_with_translations ===

.
=== DEBUG Raw translations from DB ===
Value: %{
  "content" => "新しいコンテンツ",
  "introduction" => "新しい紹介",
  "locale" => "ja",
  "title" => "新しいタイトル",
  "url" => "new-note"
}
=== END DEBUG Raw translations from DB ===


=== DEBUG Compiled translations from get_with_translations ===
Value: %{
  "content" => [
    {:typography, "p", %{size: "md", dropcap: true},
     ["翻訳されたコンテンツ"], %{}}
  ],
  "introduction" => "新しい紹介",
  "locale" => "ja",
  "title" => "新しいタイトル",
  "url" => "new-note"
}
=== END DEBUG Compiled translations from get_with_translations ===

.
=== DEBUG Raw translations from DB ===
Value: %{
  "content" => "更新されたコンテンツ",
  "file_path" => "ja translation for file_path",
  "introduction" => "ja translation for introduction",
  "locale" => "ja",
  "read_time" => "ja translation for read_time",
  "title" => "更新されたタイトル",
  "url" => "existing-note",
  "word_count" => "ja translation for word_count"
}
=== END DEBUG Raw translations from DB ===


=== DEBUG Compiled translations from get_with_translations ===
Value: %{
  "content" => [
    {:typography, "p", %{size: "md", dropcap: true},
     ["翻訳されたコンテンツ"], %{}}
  ],
  "file_path" => "ja translation for file_path",
  "introduction" => "ja translation for introduction",
  "locale" => "ja",
  "read_time" => "ja translation for read_time",
  "title" => "更新されたタイトル",
  "url" => "existing-note",
  "word_count" => "ja translation for word_count"
}
=== END DEBUG Compiled translations from get_with_translations ===

.
=== DEBUG Translations from get_translations ===
Value: %{
  "company" => "日本語の会社名",
  "content" => "日本語のコンテンツ",
  "title" => "日本語のタイトル"
}
=== END DEBUG Translations from get_translations ===

......14:44:15.056 [error] Failed to clone repository: exit code 128, output: 14:44:14.656196 git.c:460               trace: built-in: git clone --verbose https://github.com/nonexistent/repo.git priv/content
Cloning into 'priv/content'...
14:44:14.664612 run-command.c:655       trace: run_command: git remote-https origin https://github.com/nonexistent/repo.git
14:44:14.667530 git.c:750               trace: exec: git-remote-https origin https://github.com/nonexistent/repo.git
14:44:14.667600 run-command.c:655       trace: run_command: git-remote-https origin https://github.com/nonexistent/repo.git
14:44:14.692165 http.c:725              == Info: Couldn't find host github.com in the (nil) file; using defaults
14:44:14.708409 http.c:725              == Info:   Trying 20.27.177.113:443...
14:44:14.721281 http.c:725              == Info: Connected to github.com (20.27.177.113) port 443 (#0)
14:44:14.836670 http.c:725              == Info: found 420 certificates in /etc/ssl/certs
14:44:14.836946 http.c:725              == Info: GnuTLS ciphers: NORMAL:-ARCFOUR-128:-CTYPE-ALL:+CTYPE-X509:-VERS-SSL3.0
14:44:14.837032 http.c:725              == Info: ALPN: offers h2,http/1.1
14:44:14.855212 http.c:725              == Info: SSL connection using TLS1.3 / ECDHE_RSA_AES_128_GCM_SHA256
14:44:14.860012 http.c:725              == Info:   server certificate verification OK
14:44:14.860038 http.c:725              == Info:   server certificate status verification SKIPPED
14:44:14.860240 http.c:725              == Info:   common name: github.com (matched)
14:44:14.860251 http.c:725              == Info:   server certificate expiration date OK
14:44:14.860257 http.c:725              == Info:   server certificate activation date OK
14:44:14.860272 http.c:725              == Info:   certificate public key: EC/ECDSA
14:44:14.860277 http.c:725              == Info:   certificate version: #3
14:44:14.860291 http.c:725              == Info:   subject: CN=github.com
14:44:14.860300 http.c:725              == Info:   start date: Wed, 05 Feb 2025 00:00:00 GMT
14:44:14.860355 http.c:725              == Info:   expire date: Thu, 05 Feb 2026 23:59:59 GMT
14:44:14.860401 http.c:725              == Info:   issuer: C=GB,ST=Greater Manchester,L=Salford,O=Sectigo Limited,CN=Sectigo ECC Domain Validation Secure Server CA
14:44:14.860424 http.c:725              == Info: ALPN: server accepted h2
14:44:14.860655 http.c:725              == Info: using HTTP/2
14:44:14.860709 http.c:725              == Info: h2h3 [:method: GET]
14:44:14.860715 http.c:725              == Info: h2h3 [:path: /nonexistent/repo.git/info/refs?service=git-upload-pack]
14:44:14.860719 http.c:725              == Info: h2h3 [:scheme: https]
14:44:14.860723 http.c:725              == Info: h2h3 [:authority: github.com]
14:44:14.860726 http.c:725              == Info: h2h3 [user-agent: git/2.39.5]
14:44:14.860729 http.c:725              == Info: h2h3 [accept: */*]
14:44:14.860732 http.c:725              == Info: h2h3 [accept-encoding: deflate, gzip, br, zstd]
14:44:14.860736 http.c:725              == Info: h2h3 [accept-language: C, *;q=0.9]
14:44:14.860739 http.c:725              == Info: h2h3 [pragma: no-cache]
14:44:14.860743 http.c:725              == Info: h2h3 [git-protocol: version=2]
14:44:14.860752 http.c:725              == Info: Using Stream ID: 1 (easy handle 0x5e97a3236060)
14:44:14.860825 http.c:672              => Send header, 0000000239 bytes (0x000000ef)
14:44:14.860836 http.c:684              => Send header: GET /nonexistent/repo.git/info/refs?service=git-upload-pack HTTP/2
14:44:14.860840 http.c:684              => Send header: Host: github.com
14:44:14.860843 http.c:684              => Send header: user-agent: git/2.39.5
14:44:14.860847 http.c:684              => Send header: accept: */*
14:44:14.860852 http.c:684              => Send header: accept-encoding: deflate, gzip, br, zstd
14:44:14.860855 http.c:684              => Send header: accept-language: C, *;q=0.9
14:44:14.860859 http.c:684              => Send header: pragma: no-cache
14:44:14.860862 http.c:684              => Send header: git-protocol: version=2
14:44:14.860865 http.c:684              => Send header:
14:44:15.044014 http.c:672              <= Recv header, 0000000013 bytes (0x0000000d)
14:44:15.044052 http.c:684              <= Recv header: HTTP/2 401
14:44:15.044060 http.c:672              <= Recv header, 0000000026 bytes (0x0000001a)
14:44:15.044068 http.c:684              <= Recv header: server: GitHub-Babel/3.0
14:44:15.044077 http.c:672              <= Recv header, 0000000054 bytes (0x00000036)
14:44:15.044083 http.c:684              <= Recv header: content-security-policy: default-src 'none'; sandbox
14:44:15.044090 http.c:672              <= Recv header, 0000000041 bytes (0x00000029)
14:44:15.044094 http.c:684              <= Recv header: content-type: text/plain; charset=UTF-8
14:44:15.044102 http.c:672              <= Recv header, 0000000040 bytes (0x00000028)
14:44:15.044107 http.c:684              <= Recv header: www-authenticate: Basic realm="GitHub"
14:44:15.044114 http.c:672              <= Recv header, 0000000020 bytes (0x00000014)
14:44:15.044117 http.c:684              <= Recv header: content-length: 21
14:44:15.044121 http.c:672              <= Recv header, 0000000037 bytes (0x00000025)
14:44:15.044125 http.c:684              <= Recv header: date: Wed, 26 Mar 2025 14:44:14 GMT
14:44:15.044129 http.c:672              <= Recv header, 0000000023 bytes (0x00000017)
14:44:15.044134 http.c:684              <= Recv header: x-frame-options: DENY
14:44:15.044140 http.c:672              <= Recv header, 0000000073 bytes (0x00000049)
14:44:15.044145 http.c:684              <= Recv header: strict-transport-security: max-age=31536000; includeSubDomains; preload
14:44:15.044151 http.c:672              <= Recv header, 0000000056 bytes (0x00000038)
14:44:15.044155 http.c:684              <= Recv header: x-github-request-id: 6E47:17498:14DFC8:1AF247:67E412BE
14:44:15.044163 http.c:672              <= Recv header, 0000000002 bytes (0x00000002)
14:44:15.044167 http.c:684              <= Recv header:
14:44:15.044208 http.c:725              == Info: Connection #0 to host github.com left intact
fatal: could not read Username for 'https://github.com': terminal prompts disabled

14:44:15.061 [error] Failed to sync repository: Failed to clone repository: 14:44:14.656196 git.c:460               trace: built-in: git clone --verbose https://github.com/nonexistent/repo.git priv/content
Cloning into 'priv/content'...
14:44:14.664612 run-command.c:655       trace: run_command: git remote-https origin https://github.com/nonexistent/repo.git
14:44:14.667530 git.c:750               trace: exec: git-remote-https origin https://github.com/nonexistent/repo.git
14:44:14.667600 run-command.c:655       trace: run_command: git-remote-https origin https://github.com/nonexistent/repo.git
14:44:14.692165 http.c:725              == Info: Couldn't find host github.com in the (nil) file; using defaults
14:44:14.708409 http.c:725              == Info:   Trying 20.27.177.113:443...
14:44:14.721281 http.c:725              == Info: Connected to github.com (20.27.177.113) port 443 (#0)
14:44:14.836670 http.c:725              == Info: found 420 certificates in /etc/ssl/certs
14:44:14.836946 http.c:725              == Info: GnuTLS ciphers: NORMAL:-ARCFOUR-128:-CTYPE-ALL:+CTYPE-X509:-VERS-SSL3.0
14:44:14.837032 http.c:725              == Info: ALPN: offers h2,http/1.1
14:44:14.855212 http.c:725              == Info: SSL connection using TLS1.3 / ECDHE_RSA_AES_128_GCM_SHA256
14:44:14.860012 http.c:725              == Info:   server certificate verification OK
14:44:14.860038 http.c:725              == Info:   server certificate status verification SKIPPED
14:44:14.860240 http.c:725              == Info:   common name: github.com (matched)
14:44:14.860251 http.c:725              == Info:   server certificate expiration date OK
14:44:14.860257 http.c:725              == Info:   server certificate activation date OK
14:44:14.860272 http.c:725              == Info:   certificate public key: EC/ECDSA
14:44:14.860277 http.c:725              == Info:   certificate version: #3
14:44:14.860291 http.c:725              == Info:   subject: CN=github.com
14:44:14.860300 http.c:725              == Info:   start date: Wed, 05 Feb 2025 00:00:00 GMT
14:44:14.860355 http.c:725              == Info:   expire date: Thu, 05 Feb 2026 23:59:59 GMT
14:44:14.860401 http.c:725              == Info:   issuer: C=GB,ST=Greater Manchester,L=Salford,O=Sectigo Limited,CN=Sectigo ECC Domain Validation Secure Server CA
14:44:14.860424 http.c:725              == Info: ALPN: server accepted h2
14:44:14.860655 http.c:725              == Info: using HTTP/2
14:44:14.860709 http.c:725              == Info: h2h3 [:method: GET]
14:44:14.860715 http.c:725              == Info: h2h3 [:path: /nonexistent/repo.git/info/refs?service=git-upload-pack]
14:44:14.860719 http.c:725              == Info: h2h3 [:scheme: https]
14:44:14.860723 http.c:725              == Info: h2h3 [:authority: github.com]
14:44:14.860726 http.c:725              == Info: h2h3 [user-agent: git/2.39.5]
14:44:14.860729 http.c:725              == Info: h2h3 [accept: */*]
14:44:14.860732 http.c:725              == Info: h2h3 [accept-encoding: deflate, gzip, br, zstd]
14:44:14.860736 http.c:725              == Info: h2h3 [accept-language: C, *;q=0.9]
14:44:14.860739 http.c:725              == Info: h2h3 [pragma: no-cache]
14:44:14.860743 http.c:725              == Info: h2h3 [git-protocol: version=2]
14:44:14.860752 http.c:725              == Info: Using Stream ID: 1 (easy handle 0x5e97a3236060)
14:44:14.860825 http.c:672              => Send header, 0000000239 bytes (0x000000ef)
14:44:14.860836 http.c:684              => Send header: GET /nonexistent/repo.git/info/refs?service=git-upload-pack HTTP/2
14:44:14.860840 http.c:684              => Send header: Host: github.com
14:44:14.860843 http.c:684              => Send header: user-agent: git/2.39.5
14:44:14.860847 http.c:684              => Send header: accept: */*
14:44:14.860852 http.c:684              => Send header: accept-encoding: deflate, gzip, br, zstd
14:44:14.860855 http.c:684              => Send header: accept-language: C, *;q=0.9
14:44:14.860859 http.c:684              => Send header: pragma: no-cache
14:44:14.860862 http.c:684              => Send header: git-protocol: version=2
14:44:14.860865 http.c:684              => Send header:
14:44:15.044014 http.c:672              <= Recv header, 0000000013 bytes (0x0000000d)
14:44:15.044052 http.c:684              <= Recv header: HTTP/2 401
14:44:15.044060 http.c:672              <= Recv header, 0000000026 bytes (0x0000001a)
14:44:15.044068 http.c:684              <= Recv header: server: GitHub-Babel/3.0
14:44:15.044077 http.c:672              <= Recv header, 0000000054 bytes (0x00000036)
14:44:15.044083 http.c:684              <= Recv header: content-security-policy: default-src 'none'; sandbox
14:44:15.044090 http.c:672              <= Recv header, 0000000041 bytes (0x00000029)
14:44:15.044094 http.c:684              <= Recv header: content-type: text/plain; charset=UTF-8
14:44:15.044102 http.c:672              <= Recv header, 0000000040 bytes (0x00000028)
14:44:15.044107 http.c:684              <= Recv header: www-authenticate: Basic realm="GitHub"
14:44:15.044114 http.c:672              <= Recv header, 0000000020 bytes (0x00000014)
14:44:15.044117 http.c:684              <= Recv header: content-length: 21
14:44:15.044121 http.c:672              <= Recv header, 0000000037 bytes (0x00000025)
14:44:15.044125 http.c:684              <= Recv header: date: Wed, 26 Mar 2025 14:44:14 GMT
14:44:15.044129 http.c:672              <= Recv header, 0000000023 bytes (0x00000017)
14:44:15.044134 http.c:684              <= Recv header: x-frame-options: DENY
14:44:15.044140 http.c:672              <= Recv header, 0000000073 bytes (0x00000049)
14:44:15.044145 http.c:684              <= Recv header: strict-transport-security: max-age=31536000; includeSubDomains; preload
14:44:15.044151 http.c:672              <= Recv header, 0000000056 bytes (0x00000038)
14:44:15.044155 http.c:684              <= Recv header: x-github-request-id: 6E47:17498:14DFC8:1AF247:67E412BE
14:44:15.044163 http.c:672              <= Recv header, 0000000002 bytes (0x00000002)
14:44:15.044167 http.c:684              <= Recv header:
14:44:15.044208 http.c:725              == Info: Connection #0 to host github.com left intact
fatal: could not read Username for 'https://github.com': terminal prompts disabled

.14:44:15.198 [warning] Request received in Endpoint: "GET" "/en/case-study/case-study-5571"
14:44:15.426 request_id=GDBhf1FqK_6InP0AABYC [warning] [SetLocale] Invalid route after setting locale
.14:44:16.279 [warning] Request received in Endpoint: "GET" "/ja/case-study/case-study-1826"
14:44:16.281 request_id=GDBhf48CxIgi1FIAAAdB [warning] [SetLocale] Invalid route after setting locale
.14:44:16.440 [warning] Request received in Endpoint: "GET" "/en/case-study/non-existent-url"
14:44:16.441 request_id=GDBhf5iT2OI5eOEAABaC [warning] [SetLocale] Invalid route after setting locale
14:44:16.443 request_id=GDBhf5iT2OI5eOEAABaC [warning] No case_study found for identifier: "non-existent-url"
14:44:16.443 request_id=GDBhf5iT2OI5eOEAABaC [error] Case study not found in database for URL: non-existent-url
14:44:16.446 request_id=GDBhf5iT2OI5eOEAABaC [warning] No case_study found for identifier: "non-existent-url"
.....14:44:17.030 [warning] Request received in Endpoint: "GET" "/en/invalid-path"
.14:44:17.147 [warning] Request received in Endpoint: "GET" "/en/"
14:44:17.198 request_id=GDBhf8KxS3RtFTQAABbC [warning] Request received in Endpoint: "GET" "/ja/"
.14:44:17.313 [warning] Request received in Endpoint: "GET" "/EN"
14:44:17.328 request_id=GDBhf8ye9J5P8m8AABdC [warning] Request received in Endpoint: "GET" "/JA"
.14:44:17.449 [warning] Request received in Endpoint: "GET" "/"
.14:44:17.563 [warning] Request received in Endpoint: "GET" "/xyz/"
.14:44:17.670 [warning] Request received in Endpoint: "GET" "/notes"
.14:44:17.778 [warning] Request received in Endpoint: "GET" "/xyz/case-study/helping-people-find-healthcare"
.14:44:17.883 [warning] Request received in Endpoint: "GET" "/"
.

  4) test handle_info/2 processes relevant file changes (Portfolio.Content.FileManagement.WatcherTest)
     test/portfolio/content/file_management/watcher_test.exs:12
     ** (FunctionClauseError) no function clause matching in Portfolio.Content.EntryManager.serialize_attrs/1

     The following arguments were given to Portfolio.Content.EntryManager.serialize_attrs/1:

         # 1
         []

     Attempted function clauses (showing 2 out of 2):

         defp serialize_attrs(attrs) when is_map(attrs)
         defp serialize_attrs(nil)

     code: capture_log(fn ->
     stacktrace:
       (portfolio 0.4.1-alpha.1) Portfolio.Content.EntryManager.serialize_attrs/1
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/managers/entry_manager.ex:654: Portfolio.Content.EntryManager.serialize_ast_node/1
       (elixir 1.17.2) lib/enum.ex:1703: Enum."-map/2-lists^map/1-1-"/2
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/managers/entry_manager.ex:665: Portfolio.Content.EntryManager.serialize_ast_node/1
       (elixir 1.17.2) lib/enum.ex:1703: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.17.2) lib/enum.ex:1703: Enum."-map/2-lists^map/1-1-"/2
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/managers/entry_manager.ex:89: Portfolio.Content.EntryManager.compile_content/2
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/managers/entry_manager.ex:56: Portfolio.Content.EntryManager.create_content/1
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/managers/entry_manager.ex:560: Portfolio.Content.EntryManager.upsert_from_file/2
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/file_management/watcher.ex:71: Portfolio.Content.FileManagement.Watcher.process_file_change/1
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/file_management/watcher.ex:48: Portfolio.Content.FileManagement.Watcher.handle_info/2
       (ex_unit 1.17.2) lib/ex_unit/capture_log.ex:113: ExUnit.CaptureLog.with_log/2
       (ex_unit 1.17.2) lib/ex_unit/capture_log.ex:75: ExUnit.CaptureLog.capture_log/2
       test/portfolio/content/file_management/watcher_test.exs:18: (test)



  5) test handle_info/2 handle_info/2 ignores irrelevant events on markdown files (Portfolio.Content.FileManagement.WatcherTest)
     test/portfolio/content/file_management/watcher_test.exs:27
     ** (FunctionClauseError) no function clause matching in Portfolio.Content.EntryManager.serialize_attrs/1

     The following arguments were given to Portfolio.Content.EntryManager.serialize_attrs/1:

         # 1
         []

     Attempted function clauses (showing 2 out of 2):

         defp serialize_attrs(attrs) when is_map(attrs)
         defp serialize_attrs(nil)

     code: Watcher.handle_info(
     stacktrace:
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/managers/entry_manager.ex:690: Portfolio.Content.EntryManager.serialize_attrs/1
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/managers/entry_manager.ex:654: Portfolio.Content.EntryManager.serialize_ast_node/1
       (elixir 1.17.2) lib/enum.ex:1703: Enum."-map/2-lists^map/1-1-"/2
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/managers/entry_manager.ex:665: Portfolio.Content.EntryManager.serialize_ast_node/1
       (elixir 1.17.2) lib/enum.ex:1703: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.17.2) lib/enum.ex:1703: Enum."-map/2-lists^map/1-1-"/2
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/managers/entry_manager.ex:89: Portfolio.Content.EntryManager.compile_content/2
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/managers/entry_manager.ex:56: Portfolio.Content.EntryManager.create_content/1
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/managers/entry_manager.ex:560: Portfolio.Content.EntryManager.upsert_from_file/2
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/file_management/watcher.ex:71: Portfolio.Content.FileManagement.Watcher.process_file_change/1
       (portfolio 0.4.1-alpha.1) lib/portfolio/content/file_management/watcher.ex:48: Portfolio.Content.FileManagement.Watcher.handle_info/2
       test/portfolio/content/file_management/watcher_test.exs:35: (test)

.14:44:18.624 [warning] Request received in Endpoint: "GET" "/"
.14:44:18.732 [warning] Request received in Endpoint: "GET" "/"
.14:44:18.834 [warning] Request received in Endpoint: "GET" "/"
.14:44:18.942 [warning] Request received in Endpoint: "GET" "/"
.14:44:19.050 [warning] Request received in Endpoint: "GET" "/"
.14:44:19.157 [warning] Request received in Endpoint: "GET" "/"
.....14:44:19.693 [warning] Request received in Endpoint: "GET" "/en"
.14:44:19.842 [warning] Request received in Endpoint: "GET" "/ja"
.14:44:19.991 [warning] Request received in Endpoint: "GET" "/"
.14:44:20.100 [warning] Request received in Endpoint: "GET" "/ja"
.14:44:20.242 [warning] Request received in Endpoint: "GET" "/non-existent-route"
.14:44:20.354 [warning] Request received in Endpoint: "GET" "/invalid-locale"
.Cloning into 'priv/content'...
remote: Enumerating objects: 100, done.
remote: Counting objects: 100% (100/100), done.
remote: Compressing objects: 100% (74/74), done.
remote: Total 100 (delta 12), reused 90 (delta 8), pack-reused 0 (from 0)
Receiving objects: 100% (100/100), 11.56 MiB | 10.79 MiB/s, done.
Resolving deltas: 100% (12/12), done.
.Cloning into 'priv/content'...
remote: Enumerating objects: 100, done.
remote: Counting objects: 100% (100/100), done.
remote: Compressing objects: 100% (74/74), done.
remote: Total 100 (delta 12), reused 90 (delta 8), pack-reused 0 (from 0)
Receiving objects: 100% (100/100), 11.56 MiB | 5.40 MiB/s, done.
Resolving deltas: 100% (12/12), done.
14:44:28.602 [error] Failed to clone repository: exit code 128, output: 14:44:27.138517 git.c:460               trace: built-in: git clone --verbose https://invalid-url.com/repo.git priv/content
Cloning into 'priv/content'...
14:44:27.147629 run-command.c:655       trace: run_command: git remote-https origin https://invalid-url.com/repo.git
14:44:27.149846 git.c:750               trace: exec: git-remote-https origin https://invalid-url.com/repo.git
14:44:27.149923 run-command.c:655       trace: run_command: git-remote-https origin https://invalid-url.com/repo.git
14:44:27.162457 http.c:725              == Info: Couldn't find host invalid-url.com in the (nil) file; using defaults
14:44:27.360738 http.c:725              == Info:   Trying 103.224.212.213:443...
14:44:27.486549 http.c:725              == Info: Connected to invalid-url.com (103.224.212.213) port 443 (#0)
14:44:27.611851 http.c:725              == Info: found 420 certificates in /etc/ssl/certs
14:44:27.612209 http.c:725              == Info: GnuTLS ciphers: NORMAL:-ARCFOUR-128:-CTYPE-ALL:+CTYPE-X509:-VERS-SSL3.0
14:44:27.612583 http.c:725              == Info: ALPN: offers h2,http/1.1
14:44:27.761036 http.c:725              == Info: SSL connection using TLS1.3 / ECDHE_RSA_AES_256_GCM_SHA384
14:44:27.766041 http.c:725              == Info:   server certificate verification OK
14:44:27.766123 http.c:725              == Info:   server certificate status verification SKIPPED
14:44:27.767519 http.c:725              == Info:   common name: stiegthmyzem.xyz (matched)
14:44:27.767578 http.c:725              == Info:   server certificate expiration date OK
14:44:27.767589 http.c:725              == Info:   server certificate activation date OK
14:44:27.767632 http.c:725              == Info:   certificate public key: RSA
14:44:27.767646 http.c:725              == Info:   certificate version: #3
14:44:27.767696 http.c:725              == Info:   subject: CN=stiegthmyzem.xyz
14:44:27.767718 http.c:725              == Info:   start date: Sat, 25 Jan 2025 18:25:16 GMT
14:44:27.767730 http.c:725              == Info:   expire date: Fri, 25 Apr 2025 18:25:15 GMT
14:44:27.767770 http.c:725              == Info:   issuer: C=US,O=Let's Encrypt,CN=R11
14:44:27.767837 http.c:725              == Info: ALPN: server did not agree on a protocol. Uses default.
14:44:27.767866 http.c:725              == Info: using HTTP/1.x
14:44:27.768731 http.c:672              => Send header, 0000000234 bytes (0x000000ea)
14:44:27.768849 http.c:684              => Send header: GET /repo.git/info/refs?service=git-upload-pack HTTP/1.1
14:44:27.768898 http.c:684              => Send header: Host: invalid-url.com
14:44:27.768924 http.c:684              => Send header: User-Agent: git/2.39.5
14:44:27.768952 http.c:684              => Send header: Accept: */*
14:44:27.768984 http.c:684              => Send header: Accept-Encoding: deflate, gzip, br, zstd
14:44:27.769019 http.c:684              => Send header: Accept-Language: C, *;q=0.9
14:44:27.769058 http.c:684              => Send header: Pragma: no-cache
14:44:27.769092 http.c:684              => Send header: Git-Protocol: version=2
14:44:27.769120 http.c:684              => Send header:
14:44:28.238157 http.c:672              <= Recv header, 0000000020 bytes (0x00000014)
14:44:28.238216 http.c:684              <= Recv header: HTTP/1.1 302 Found
14:44:28.238234 http.c:672              <= Recv header, 0000000037 bytes (0x00000025)
14:44:28.238242 http.c:684              <= Recv header: date: Wed, 26 Mar 2025 14:44:27 GMT
14:44:28.238256 http.c:672              <= Recv header, 0000000016 bytes (0x00000010)
14:44:28.238262 http.c:684              <= Recv header: server: Apache
14:44:28.238268 http.c:672              <= Recv header, 0000000096 bytes (0x00000060)
14:44:28.238278 http.c:684              <= Recv header: set-cookie: __tad=1743000267.2766398; expires=Sat, 24-Mar-2035 14:44:27 GMT; Max-Age=315360000
14:44:28.238291 http.c:672              <= Recv header, 0000000126 bytes (0x0000007e)
14:44:28.238299 http.c:684              <= Recv header: location: http://ww25.invalid-url.com/repo.git/info/refs?service=git-upload-pack&subid1=20250327-0144-27ea-b1d2-611d7c7835d3
14:44:28.238334 http.c:672              <= Recv header, 0000000019 bytes (0x00000013)
14:44:28.238347 http.c:684              <= Recv header: content-length: 2
14:44:28.238356 http.c:672              <= Recv header, 0000000040 bytes (0x00000028)
14:44:28.238363 http.c:684              <= Recv header: content-type: text/html; charset=UTF-8
14:44:28.238376 http.c:672              <= Recv header, 0000000019 bytes (0x00000013)
14:44:28.238380 http.c:684              <= Recv header: connection: close
14:44:28.238391 http.c:672              <= Recv header, 0000000002 bytes (0x00000002)
14:44:28.238396 http.c:684              <= Recv header:
14:44:28.238446 http.c:725              == Info: Closing connection 0
14:44:28.251753 http.c:725              == Info: Clear auth, redirects to port from 443 to 80
14:44:28.252737 http.c:725              == Info: Issue another request to this URL: 'http://ww25.invalid-url.com/repo.git/info/refs?service=git-upload-pack&subid1=20250327-0144-27ea-b1d2-611d7c7835d3'
14:44:28.253024 http.c:725              == Info: Couldn't find host ww25.invalid-url.com in the (nil) file; using defaults
14:44:28.269462 http.c:725              == Info:   Trying 199.59.243.228:80...
14:44:28.286640 http.c:725              == Info: Connected to ww25.invalid-url.com (199.59.243.228) port 80 (#1)
14:44:28.287001 http.c:672              => Send header, 0000000283 bytes (0x0000011b)
14:44:28.287014 http.c:684              => Send header: GET /repo.git/info/refs?service=git-upload-pack&subid1=20250327-0144-27ea-b1d2-611d7c7835d3 HTTP/1.1
14:44:28.287018 http.c:684              => Send header: Host: ww25.invalid-url.com
14:44:28.287021 http.c:684              => Send header: User-Agent: git/2.39.5
14:44:28.287026 http.c:684              => Send header: Accept: */*
14:44:28.287030 http.c:684              => Send header: Accept-Encoding: deflate, gzip, br, zstd
14:44:28.287035 http.c:684              => Send header: Accept-Language: C, *;q=0.9
14:44:28.287038 http.c:684              => Send header: Pragma: no-cache
14:44:28.287041 http.c:684              => Send header: Git-Protocol: version=2
14:44:28.287044 http.c:684              => Send header:
14:44:28.587725 http.c:672              <= Recv header, 0000000017 bytes (0x00000011)
14:44:28.587780 http.c:684              <= Recv header: HTTP/1.1 200 OK
14:44:28.587798 http.c:672              <= Recv header, 0000000037 bytes (0x00000025)
14:44:28.587804 http.c:684              <= Recv header: date: Wed, 26 Mar 2025 14:44:28 GMT
14:44:28.587815 http.c:672              <= Recv header, 0000000040 bytes (0x00000028)
14:44:28.587822 http.c:684              <= Recv header: content-type: text/html; charset=utf-8
14:44:28.587831 http.c:672              <= Recv header, 0000000022 bytes (0x00000016)
14:44:28.587838 http.c:684              <= Recv header: content-length: 1278
14:44:28.587844 http.c:672              <= Recv header, 0000000052 bytes (0x00000034)
14:44:28.587850 http.c:684              <= Recv header: x-request-id: b92feca5-ffba-47d4-8cd2-eec64994a721
14:44:28.587856 http.c:672              <= Recv header, 0000000036 bytes (0x00000024)
14:44:28.587867 http.c:684              <= Recv header: cache-control: no-store, max-age=0
14:44:28.587875 http.c:672              <= Recv header, 0000000040 bytes (0x00000028)
14:44:28.587882 http.c:684              <= Recv header: accept-ch: sec-ch-prefers-color-scheme
14:44:28.587887 http.c:672              <= Recv header, 0000000042 bytes (0x0000002a)
14:44:28.587894 http.c:684              <= Recv header: critical-ch: sec-ch-prefers-color-scheme
14:44:28.587901 http.c:672              <= Recv header, 0000000035 bytes (0x00000023)
14:44:28.587906 http.c:684              <= Recv header: vary: sec-ch-prefers-color-scheme
14:44:28.587914 http.c:672              <= Recv header, 0000000234 bytes (0x000000ea)
14:44:28.587926 http.c:684              (truncated)
.Cloning into 'priv/content'...
remote: Enumerating objects: 100, done.
remote: Counting objects: 100% (100/100), done.
remote: Compressing objects: 100% (74/74), done.
remote: Total 100 (delta 12), reused 90 (delta 8), pack-reused 0 (from 0)
Receiving objects: 100% (100/100), 11.56 MiB | 3.16 MiB/s, done.
Resolving deltas: 100% (12/12), done.
................14:44:35.376 [warning] Request received in Endpoint: "GET" "/en/case-studies"
.14:44:35.529 [warning] Request received in Endpoint: "GET" "/ja/case-studies"
.*14:44:35.678 [warning] Request received in Endpoint: "GET" "/case-studies/"
.14:44:35.785 [warning] Request received in Endpoint: "GET" "/"
.14:44:35.888 [warning] Request received in Endpoint: "GET" "/en/"
.14:44:36.004 [warning] Request received in Endpoint: "GET" "/"
.14:44:36.107 [warning] Request received in Endpoint: "GET" "/images/logo.png"
.14:44:36.210 [warning] Request received in Endpoint: "GET" "/"
.14:44:36.314 [warning] Request received in Endpoint: "GET" "/"
.14:44:36.419 [warning] Request received in Endpoint: "GET" "/"
.14:44:36.525 [warning] Request received in Endpoint: "GET" "/en/case-studies/"
.14:44:36.643 [warning] Request received in Endpoint: "GET" "/unsupported_locale/"
.14:44:36.749 [warning] Request received in Endpoint: "GET" "/"
....................................................
Finished in 50.0 seconds (4.7s async, 45.3s sync)
247 tests, 5 failures, 1 skipped


Task completed in 0m54.112s