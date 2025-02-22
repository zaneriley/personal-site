Summary
• Given your need for custom transformations, dynamic dropcaps, and specialized handling of images and punctuation, the AST → Phoenix Components approach is almost certainly your best bet.
• Keep your existing “parse to AST” logic in CustomParser, but remove or rewrite the final “compile to raw HTML” step. Instead, produce structured data and feed it into a Phoenix function component that calls <.typography> (and other UI components) for each node.
CustomParser.parse(markdown) → returns a custom AST of nodes including headings, paragraphs, images, etc.
HTMLCompiler.render(custom_ast) → today it emits raw HTML.
To shift toward function components, you have two broad options:
“Stringify” your function-component calls after AST transformations.
Instead of building raw HTML strings in HTMLCompiler, literally build something like:
" <.typography tag=\"h1\" locale=\"en\" dropcap=\"true\">Title</.typography>"
Then at runtime, in a Phoenix .html.heex file (or a LiveView ~H""), you do <%= raw(@complete_markup_with_typography_calls) %> so Phoenix interprets them as if you typed them in your template.
Downside: The <.typography> calls are first turned into strings, then re-parsed by Phoenix’s engine. This can be brittle if your indentation or quotes get tricky.
Return the AST as data, then do the final rendering with a Phoenix function component that walks the data.
For example, pass the AST to a function like <.render_ast ast={@my_ast} />.
Within that function, pattern match on each node: if it’s a heading node, render <.typography tag="h1" size="4xl">; if it’s a paragraph, apply dropcap logic, etc.
This is highly flexible and doesn’t require string manipulations. However, it does mean writing code to recursively traverse your AST in a LiveComponent or function component.
Each subnode can be turned into <.typography …> calls. You can also create a <.custom_image> component (or reuse an existing one) to handle images.
Option #2 is usually the “cleanest” from a maintainability standpoint. You can create a single function that does:
```
defmodule MyAppWeb.AstRenderer do
  use Phoenix.Component
  
  def render_ast(assigns) do
    ~H"""
    <%= for node <- @ast do %>
      <%= render_node(node) %>
    <% end %>
    """
  end

  defp render_node({:paragraph, content, meta}) do
    ~H"""
    <.typography
      tag="p"
      dropcap={!!meta[:dropcap]}
      locale={@locale}
      class="my-custom-class"
    >
      <%= raw(content) %>
    </.typography>
    """
  end

  defp render_node({:heading, level, content, meta}) do
    ~H"""
    <.typography
      tag={"h#{level}"}
      dropcap={false}
      locale={@locale}
    >
      <%= raw(content) %>
    </.typography>
    """
  end

  # And so on for images, lists, etc.
end
```
Then in your LiveView or controller templates, you pass the AST to <.render_ast>:
```
<.render_ast ast={@my_parsed_ast} locale={@locale} />
```
That final step is where Phoenix’s change tracking can see changes in the AST, re-render only the changed nodes, and attach all your custom styling logic in a centralized manner.
---
Summary
• Given your need for custom transformations, dynamic dropcaps, and specialized handling of images and punctuation, the AST → Phoenix Components approach is almost certainly your best bet.
• Keep your existing “parse to AST” logic in CustomParser, but remove or rewrite the final “compile to raw HTML” step. Instead, produce structured data and feed it into a Phoenix function component that calls <.typography> (and other UI components) for each node.
