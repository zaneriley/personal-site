# ADR 0005 — Publish-time syntax highlighting through the content pipeline

**Status:** accepted 2026-06-10; implemented in commits df1d68f (component + color tokens), 7b4469e (tokenizer + pipeline), ed00ce1 (render-path generalization), 7594d6c (type-contract fix), a74f68c (boundary docs).
**Supersedes:** none.
**Superseded by:** none.

This ADR records how fenced code in markdown becomes the syntax-colored code-block component: where tokenization happens, what the contracts between the tokenizer, the stored content, the component, and the theme are, and why the work is paid at publish time rather than at request time or in the browser. Ratified through Z's in-session decisions during the code-block build (2026-06-10).

## Context

The site renders source code in articles (Elixir, Rust, CSS, YAML, and more) inside the code-block component designed in Figma: a framed listing with a file-path header, line-number gutter, scroll scrim, and a nine-color syntax palette drawn from the site's own warm scheme — not an off-the-shelf highlighter theme.

Three constraints shaped the design:

1. **The 200 ms cold-load budget.** Whatever colors the code must not run on the request path or in the browser. A client-side highlighter (Prism/highlight.js/Shiki) ships JS, runs after paint, and recolors on screen — directly against the budget. Render-time tokenization on the server re-pays the cost per request unless cached.
2. **Content/site decoupling.** Authored markdown must stay standard CommonMark and render acceptably in GitHub or Obsidian. No custom component syntax for something as ordinary as a code snippet.
3. **The pipeline already bakes.** Content compiles once (`Compiler.compile/2`) into a `stored_ast` persisted to the DB; requests deserialize and render. The long-standing `process_ast` TODO ("apply transforms like syntax highlighting") marked exactly where a compile-time transform belongs.

Two reality checks during the build constrained it further:

- **Earmark cannot parse multi-word fence info strings.** ` ```elixir lib/a.ex ` — valid CommonMark — degrades the entire fence into inline code. The filename-in-info-string authoring convention therefore needs a parser-side workaround, not an Earmark feature.
- **Makeup was ruled out, and Autumn got renamed.** Makeup's lexers don't cover Rust/CSS/YAML. The tree-sitter engine chosen (precompiled NIF, broad grammar coverage, class-based output) ships today as `lumis` (the package formerly named `autumn`). Its `html_linked` output speaks tree-sitter capture vocabulary (`keyword-function`, `string-special-symbol`) wrapped in per-line divs — vocabulary and structure that must not leak into stored content.

## Decision

**Tokenize once at publish, bake the classified HTML into `stored_ast`.** A pipeline transform (`Transforms.CodeBlock`) rewrites each fenced `pre>code` node into `{:component, :code_block, attrs, [], meta}` whose `"code"` attr is the classified HTML. It runs from `Compiler.process_ast/2` through the existing Pipeline stage mechanism (`@compile_stages`), in the compile path before storage. The same call on the read path is a cheap no-op walk — fence nodes are already components. Serving a post does zero tokenizing.

**The `tok-*` classes are the one contract between tokenizer and theme.** Classified HTML carries semantic classes (`tok-keyword`, `tok-atom`, `tok-module`, `tok-function`, `tok-type`, `tok-call`, `tok-attribute`, `tok-string`, `tok-comment`, `tok-operator`, `tok-punctuation`, `tok-number`); colors come entirely from CSS (`_code.css` maps role → hue primitive; `_color.css` holds per-theme hue values). Changing a color recolors every post instantly with no recompile; renaming a `tok-*` class is a content-recompile event. Roles that share a hue today (atom/keyword, string/comment) keep separate classes so they can diverge later without re-baking.

**The engine lives behind a one-callback boundary.** `Portfolio.Content.Code.Tokenizer` (`classify(source, language) :: {:ok, tok_html} | {:error, reason}`). The `Tokenizer.Lumis` implementation contains ALL vendor vocabulary: it unwraps the engine's pre/line-div structure into plain newline-separated HTML and maps capture names onto `tok-*` by longest prefix; unmapped captures lose their class (plain text) rather than leaking. Swapping engines means rewriting that one file.

**Highlighting is enhancement; publishing never blocks on it.** Unknown languages and `nil` languages yield plain escaped code as `{:ok, …}`. The engine's only failure mode is raising (its success typing is `{:ok, binary()}`), which the implementation rescues into the behaviour's `{:error, …}`; the transform degrades that to plain escaped code.

**The copy guarantee: text content survives classification exactly.** Token spans never alter or introduce text, so the browser's `textContent` of the rendered block *is* the source — the copy button reads the DOM and the code ships exactly once. Pinned by test.

**Authoring stays standard CommonMark; the parser works around Earmark.** The fence info string is `language [filename]` (` ```elixir lib/a.ex `). The parser lifts filenames off fence lines before Earmark runs (one queue entry per fence) and re-attaches them as `data-filename` by document order afterwards. Known limit, accepted: an indented 4-space code block between fences shifts the correlation — we author exclusively with fences. The authoring rules live in `_PROJECT_DOCS/content-authoring-contract.md`.

**The component is presentation only.** `PortfolioWeb.Components.CodeBlock` consumes already-classified HTML (or plain strings, which it escapes), derives line numbers from the code, splits the file path into dimmed-directory/emphasized-basename, and renders the chrome. It never tokenizes. Chrome markup renders at request time from the component, so the design can evolve without recompiling content — only token spans are baked.

**The renderer owns converting component results to HTML.** Registered components are applied with the pipeline assigns shape (`%{component:, attrs: string-keyed, content:}`, per `Component.Definition`'s moduledoc) and may return `Rendered`/`Safe`; `render_html` normalizes once for all components. Deserialization restores component types to atoms (`String.to_existing_atom`, bounded); unknown stored types fall through to the renderer's not-found fallback instead of crashing.

## Why this direction

- **Versus a client-side highlighter:** zero JS shipped for highlighting, zero re-paint, theme switching is pure CSS because the HTML carries classes, not colors. The cold-load budget is met by construction — the request path is "read HTML, serve static CSS."
- **Versus render-time server tokenization:** the NIF cost would recur per request (or demand a cache layer with its own invalidation). Baking into `stored_ast` reuses the pipeline's existing once-at-publish model; no new moving parts.
- **Versus Makeup (pure-Elixir):** insufficient language coverage for the site's content. The Elixir-native appeal didn't survive the multi-language requirement.
- **Versus baking the full chrome:** baking only token spans keeps the volatile part (design) live and the expensive part (tokenization) cached — the split that lets `_code.css` and the component evolve freely.

## Consequences

- A `tok-*` vocabulary change requires re-compiling stored content; a color change does not. The vocabulary is therefore the stable contract — extend it rather than renaming.
- The capture→`tok-*` map in `Tokenizer.Lumis` is maintained against observed engine output. New languages may surface unmapped captures; they degrade to plain text until mapped (visible, not breaking).
- The end-to-end test (compile → JSON round trip → render) is the template for component pipeline coverage — it caught the string-vs-atom type bug that broke every registered component coming out of storage. The exposed `figure.ex` gap (registered, but can't accept the pipeline shape) is recorded in `_PROJECT_DOCS/BACKLOG.md`.
- Remaining work, deliberately out of this ADR's scope: the `CodeBlock` JS hook (copy + scrim/expand on LiveView pages — behavior proven by the `/code-block` dev page's inline script), a Typography `font="mono"` variant consuming `--font-mono`, and the in-situ category→color tuning on `/code-block`.

## Do nots

- Do not tokenize on the request path, in LiveView mounts, or in the browser.
- Do not let engine vocabulary (capture names, `lumis`/`athl` classes, line divs) into stored content — the `Tokenizer.Lumis` module is its containment boundary.
- Do not put colors in stored HTML; classes only. The theme owns color.
- Do not hand component modules their own `Rendered`→binary conversions; the renderer normalizes for everyone.
- Do not make publishing depend on highlighting succeeding.
