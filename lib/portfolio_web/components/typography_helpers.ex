defmodule PortfolioWeb.Components.TypographyHelpers do
  @moduledoc """
  Provides helper functions for building typography-related CSS class names with locale-specific font mappings.

  This module generates consistent and flexible class names for text elements, handling typography options such as font size,
  font family, color, alignment, and locale-specific font substitutions.

  ## Locale-Specific Font Mappings

  The `font_variants` map defines font keys that map to locale-specific font classes. This allows the same `:font` assign to use
  different fonts based on the current locale, ensuring appropriate typefaces are used for different languages.

  ## Usage

  The main function `build_class_names/2` takes a map of assigns and returns a string of CSS class names. It supports the following options:

  - `:font` - Specifies the logical font key (e.g., `"cardinal"`, `"cheee"`, `"flexa"`). The actual font applied depends on the current locale.
  - `:color` - Sets the text color (e.g., `"main"`, `"callout"`, `"deemphasized"`).
  - `:size` - Determines the font size (e.g., `"4xl"`, `"3xl"`, `"2xl"`, `"md"`).
  - `:center` - Boolean to center-align the text.
  - `:class` - Additional custom classes to be appended.
  - `:dropcap` - Boolean to apply dropcap styling.

  ### Example

      iex> assigns = %{font: "cardinal", size: "2xl", center: true, class: "custom-class", dropcap: true}
      iex> PortfolioWeb.Components.TypographyHelpers.build_class_names(assigns)
      "text-2xl text-center text-callout font-cardinal-fruit custom-class dropcap"

  """

  @doc """
  Builds a string of CSS class names based on the provided typography-related options.

  ## Parameters

    - `assigns` - A map containing typography options. Supported keys are:
      - `:font` - String, the logical font key.
      - `:color` - String, the text color name.
      - `:size` - String, the font size (default: `"md"`).
      - `:center` - Boolean, whether to center-align the text (default: `false`).
      - `:class` - String, additional custom classes (default: `""`).
      - `:dropcap` - Boolean, whether to apply dropcap styling (default: `false`).

  ## Returns

    - A string of space-separated CSS class names.

  ## Examples

      iex> build_class_names(%{font: "cheee", size: "1xl", dropcap: true})
      "text-1xl text-callout font-cheee tracking-widest dropcap"

      iex> build_class_names(%{color: "accent", center: true, dropcap: true})
      "text-md text-center text-accent font-gt-flexa dropcap"

  """
  @spec build_class_names(map(), String.t() | nil) :: String.t()
  def build_class_names(assigns, locale \\ nil) do
    size_classes = %{
      "4xl" => "text-4xl",
      "3xl" => "text-3xl",
      "2xl" => "text-2xl",
      "1xl" => "text-1xl",
      "md" => "text-md",
      "1xs" => "text-1xs",
      "2xs" => "text-2xs"
    }

    color_classes = %{
      "main" => "text-main",
      "callout" => "text-callout",
      "deemphasized" => "text-deemphasized",
      "suppressed" => "text-suppressed",
      "accent" => "text-accent"
    }

    # Default colors for specific fonts
    font_default_colors = %{
      "cheee" => "deemphasized"
    }

    # Locale-specific font mappings
    font_variants = %{
      "cardinal" => %{
        "en" => "font-cardinal-fruit",
        "ja" => "font-noto-serif-jp"
      },
      "cheee" => %{
        "en" => "font-cheee tracking-widest",
        "ja" => "font-noto-sans-jp bold"
      },
      "flexa" => %{
        "en" => "font-gt-flexa",
        "ja" => "font-ud-reimin"
      },
      "noto" => %{
        "en" => "font-noto-sans-jp",
        "ja" => "font-noto-sans-jp"
      }
    }

    locale = locale || assigns[:locale] || Gettext.get_locale()

    assigns_font = assigns[:font] || default_font_for_locale(locale)
    assigns_color = assigns[:color]
    assigns_size = assigns[:size] || "md"
    assigns_center = Map.get(assigns, :center, false)
    assigns_class = assigns[:class] || ""
    assigns_dropcap = Map.get(assigns, :dropcap, false)

    color =
      cond do
        assigns_color ->
          assigns_color

        Map.has_key?(font_default_colors, assigns_font) ->
          font_default_colors[assigns_font]

        true ->
          "main"
      end

    base_classes = [
      Map.get(size_classes, assigns_size, ""),
      if(assigns_center, do: "text-center", else: "")
    ]

    base_classes = base_classes ++ [Map.get(color_classes, color, "")]

    font_classes =
      case font_variants[assigns_font] do
        %{} = locales -> Map.get(locales, locale, locales["en"])
        nil -> ""
      end

    additional_classes = assigns_class

    [
      base_classes,
      font_classes,
      additional_classes
    ]
    |> List.flatten()
    |> Enum.filter(&(&1 != ""))
    |> Enum.join(" ")
  end

  @spec default_font_for_locale(String.t()) :: String.t()
  defp default_font_for_locale(locale) do
    case locale do
      "ja" -> "noto"
      _ -> "flexa"
    end
  end
end
