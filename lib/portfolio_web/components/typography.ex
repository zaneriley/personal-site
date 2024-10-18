defmodule PortfolioWeb.Components.Typography do
  @moduledoc """
  A flexible typography component for rendering text elements with customizable styles.

  ## Example Usage

      <.typography tag="h1" size="4xl" center={true}>Heading 1</.typography>
      <.typography tag="p" size="md" color="text-red-500">Paragraph</.typography>
      <.typography tag="p" size="1xs" font="cheee">Special Text</.typography>

  """

  use Phoenix.Component

  @doc """
  Renders a typography element with the specified attributes.

  ## Attributes

    * `:tag` - The HTML tag to use (default: `"p"`).
    * `:size` - The text size, e.g., `"4xl"`, `"md"`, `"1xs"` (default: `"md"`).
    * `:center` - Centers the text if set to `true` (default: `false`).
    * `:id` - The HTML `id` attribute (optional).
    * `:color` - Additional text color classes (optional).
    * `:font` - The font variant to use, e.g., `"cardinal"`, `"cheee"` (optional).

  ## Examples

      <.typography tag="h1" size="4xl" center={true}>Heading 1</.typography>

      <.typography tag="p" size="md" color="text-red-500">Paragraph</.typography>

      <.typography tag="p" size="1xs" font="cheee">Special Text</.typography>

  """
  @spec typography(map) :: Phoenix.LiveView.Rendered.t()
  attr :tag, :string, default: "p"
  attr :size, :string, default: "md"
  attr :center, :boolean, default: false
  attr :id, :string, default: nil
  attr :color, :string, default: nil
  attr :font, :string, default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  alias PortfolioWeb.Components.TypographyHelpers

  def typography(assigns) do
    all_classes = TypographyHelpers.build_class_names(assigns)
    assigns = assign(assigns, :all_classes, all_classes)

    ~H"""
    <.dynamic_tag name={@tag} id={@id} class={@all_classes}>
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end
end
