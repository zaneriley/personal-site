defmodule Portfolio.Content.MarkdownRendering.Renderer do
  @moduledoc """
  Handles rendering of markdown content to HTML.
  """
  def render(markdown) do
    Earmark.as_html!(markdown)
  end
end
