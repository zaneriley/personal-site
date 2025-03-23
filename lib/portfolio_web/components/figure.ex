defmodule PortfolioWeb.Components.Figure do
  @moduledoc """
  A semantic figure component for rendering images with optional captions.

  This component uses the primitive Image component internally and adds
  semantic structure with the figure and figcaption elements.

  ## Example Usage

      <.figure src="/images/example.jpg" alt="Example image" />
      <.figure src="/images/example.jpg" alt="Example image" caption="This is a caption" />
  """

  use Phoenix.Component

  use Portfolio.Content.Markdown.Component.Definition,
    type: :figure,
    function: :figure,
    description:
      "A semantic figure component for displaying images with optional captions",
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
      caption: %{
        type: :string,
        required: false,
        default: nil,
        description: "Optional caption text to display below the image"
      },
      class: %{
        type: :string,
        required: false,
        default: nil,
        description: "Additional CSS classes for the figure element"
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
      <.figure src="/images/example.jpg" alt="Example image" />
      """,
      """
      <.figure src="/images/example.jpg" alt="Example image" caption="This is a caption" />
      """
    ]

  alias PortfolioWeb.Components.{Typography, Image}

  @doc """
  Renders a figure component with an image and optional caption.

  ## Attributes

    * `:src` - The URL or path to the image (required).
    * `:alt` - Alternative text description of the image for accessibility (required).
    * `:caption` - Optional caption text to display below the image.
    * `:class` - Additional CSS classes for the figure element.
    * `:width` - Optional width attribute for the image.
    * `:height` - Optional height attribute for the image.
    * `:loading` - Image loading behavior (default: "lazy").

  ## Examples

      <.figure src="/images/example.jpg" alt="Example image" />

      <.figure src="/images/example.jpg" alt="Example image" caption="This is a caption" />

  """
  attr :src, :string, required: true
  attr :alt, :string, required: true
  attr :caption, :string, default: nil
  attr :class, :string, default: nil
  attr :width, :string, default: nil
  attr :height, :string, default: nil
  attr :loading, :string, default: "lazy"

  def figure(assigns) do
    ~H"""
    <figure class={["image-figure", @class]}>
      <Image.image
        src={@src}
        alt={@alt}
        loading={@loading}
        width={@width}
        height={@height}
      />
      <%= if @caption do %>
        <Typography.typography tag="figcaption" size="sm" class="figure-caption">
          <%= @caption %>
        </Typography.typography>
      <% end %>
    </figure>
    """
  end
end
