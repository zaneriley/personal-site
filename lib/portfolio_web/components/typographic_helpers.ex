defmodule PortfolioWeb.Components.TypographyHelpers do
  @moduledoc """
  Provides helper functions for building typography-related CSS class names.

  This module contains utilities to generate consistent and flexible class names
  for text elements, handling various typography options such as font size,
  font family, color, and alignment.

  ## Usage

  The main function `build_class_names/1` takes a map of assigns and returns
  a string of CSS class names. It supports the following options:

  - `:font` - Specifies the font family (e.g., "cardinal", "cheee", "departure")
  - `:color` - Sets the text color (e.g., "main", "callout", "deemphasized")
  - `:size` - Determines the font size (e.g., "4xl", "3xl", "2xl", "md")
  - `:center` - Boolean to center-align the text
  - `:class` - Additional custom classes to be appended

  Example:

      iex> assigns = %{font: "cardinal", size: "2xl", center: true, class: "custom-class"}
      iex> PortfolioWeb.Components.TypographyHelpers.build_class_names(assigns)
      "text-2xl text-center text-callout font-cardinal-fruit text-callout custom-class"

  """

  @doc """
  Builds a string of CSS class names based on the provided typography-related options.

  ## Parameters

  - `assigns` - A map containing typography options. Supported keys are:
    - `:font` - String, the font family name
    - `:color` - String, the text color name
    - `:size` - String, the font size name (default: "md")
    - `:center` - Boolean, whether to center-align the text (default: false)
    - `:class` - String, additional custom classes (default: "")

  ## Returns

  A string of space-separated CSS class names.

  ## Examples

      iex> build_class_names(%{font: "cheee", size: "1xl"})
      "text-1xl text-deemphasized font-cheee tracking-widest text-deemphasized"

      iex> build_class_names(%{color: "accent", center: true})
      "text-md text-center text-accent"

  """
  @spec build_class_names(map()) :: String.t()
  def build_class_names(assigns) do
    size_classes = %{
      "4xl" => "text-4xl",
      "3xl" => "text-3xl",
      "2xl" => "text-2xl",
      "1xl" => "text-1xl",
      "md" => "text-md",
      "1xs" => "text-1xs",
      "2xs" => "text-2xs"
    }

    font_variants = %{
      "cardinal" => "font-cardinal-fruit text-callout",
      "cheee" => "font-cheee tracking-widest text-deemphasized",
      "departure" => "font-departure-mono"
    }

    color_classes = %{
      "main" => "text-main",
      "callout" => "text-callout",
      "deemphasized" => "text-deemphasized",
      "suppressed" => "text-suppressed",
      "accent" => "text-accent"
    }

    font_default_colors = %{
      "cheee" => "deemphasized"
    }

    assigns_font = Map.get(assigns, :font)
    assigns_color = Map.get(assigns, :color)
    assigns_size = Map.get(assigns, :size, "md")
    assigns_center = Map.get(assigns, :center, false)
    assigns_class = Map.get(assigns, :class, "")

    color =
      cond do
        assigns_color ->
          assigns_color

        assigns_font && Map.has_key?(font_default_colors, assigns_font) ->
          font_default_colors[assigns_font]

        true ->
          "main"
      end

    base_classes = [
      Map.get(size_classes, assigns_size, ""),
      if(assigns_center, do: "text-center", else: ""),
      Map.get(color_classes, color, "")
    ]

    font_classes = Map.get(font_variants, assigns_font, "")
    additional_classes = assigns_class

    [base_classes, font_classes, additional_classes]
    |> List.flatten()
    |> Enum.filter(&(&1 != ""))
    |> Enum.join(" ")
  end
end
