defmodule PortfolioWeb.Components.Image do
  @moduledoc """
  A primitive image component that handles core image functionality.

  This component serves as a foundation for other image-related components
  and ensures consistent image handling throughout the application.

  ## Example Usage

      <.image src="/images/example.jpg" alt="Example image" />
  """

  use Phoenix.Component

  use Portfolio.Content.Markdown.Component.Definition,
    type: :image,
    function: :image,
    description: "A primitive image component for consistent image handling",
    attributes: %{
      src: %{
        type: :string,
        required: true,
        description: "The URL or path to the image"
      },
      alt: %{
        type: :string,
        required: true,
        description:
          "Alternative text description of the image for accessibility"
      },
      class: %{
        type: :string,
        required: false,
        default: nil,
        description: "Additional CSS classes for the image element"
      },
      width: %{
        type: :string,
        required: false,
        default: nil,
        description: "Optional width attribute for the image"
      },
      height: %{
        type: :string,
        required: false,
        default: nil,
        description: "Optional height attribute for the image"
      },
      loading: %{
        type: :string,
        required: false,
        default: "lazy",
        description: "Image loading behavior (lazy, eager)"
      }
    },
    examples: [
      """
      <.image src="/images/example.jpg" alt="Example image" />
      """,
      """
      <.image src="/images/example.jpg" alt="Example image" class="rounded" width="400" height="300" />
      """
    ]

  @doc """
  Renders an image with consistent behavior.

  ## Attributes

    * `:src` - The URL or path to the image (required).
    * `:alt` - Alternative text description of the image for accessibility (required).
    * `:class` - Additional CSS classes for the image element.
    * `:width` - Optional width attribute for the image.
    * `:height` - Optional height attribute for the image.
    * `:loading` - Image loading behavior (default: "lazy").

  ## Examples

      <.image src="/images/example.jpg" alt="Example image" />

      <.image
        src="/images/example.jpg"
        alt="Example image"
        class="rounded"
        width="400"
        height="300"
      />
  """
  attr :src, :string, required: true
  attr :alt, :string, required: true
  attr :class, :string, default: nil
  attr :width, :string, default: nil
  attr :height, :string, default: nil
  attr :loading, :string, default: "lazy"

  def image(assigns) do
    ~H"""
    <img
      src={@src}
      alt={@alt}
      loading={@loading}
      width={@width}
      height={@height}
      class={@class}
    />
    """
  end
end
