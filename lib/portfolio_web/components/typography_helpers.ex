defmodule PortfolioWeb.Components.TypographyHelpers do
  @moduledoc """
  Provides helper functions for building typography-related CSS class names with locale-specific font mappings.

  This module generates consistent and flexible class names for text elements, handling typography options such as font size,
  font family, color, alignment, and locale-specific font substitutions using a pipeline approach.

  ## Locale-Specific Font Mappings

  The `@font_variants` map defines font keys that map to locale-specific font classes. This allows the same `:font` assign to use
  different fonts based on the current locale, ensuring appropriate typefaces are used for different languages.

  ## Usage

  The main function `build_class_names/2` takes a map of assigns and an optional locale, returning a string of CSS class names. It supports the following options:

  - `:font` - Specifies the logical font key (e.g., `"cardinal"`, `"cheee"`, `"flexa"`). The actual font applied depends on the current locale.
  - `:color` - Sets the text color (e.g., `"main"`, `"callout"`, `"deemphasized"`).
  - `:size` - Determines the font size (e.g., `"4xl"`, `"3xl"`, `"2xl"`, `"md"`).
  - `:center` - Boolean to center-align the text.
  - `:class` - Additional custom classes to be appended.
  - `:dropcap` - Boolean to apply dropcap styling.
  - `:locale` - Explicit locale string (optional, falls back to Gettext locale).

  ### Example

      iex> assigns = %{font: "cardinal", size: "2xl", center: true, class: "custom-class", dropcap: true, locale: "en"}
      iex> PortfolioWeb.Components.TypographyHelpers.build_class_names(assigns)
      "text-2xl text-main font-cardinal-fruit text-center dropcap custom-class"

      iex> assigns = %{font: "cheee", size: "1xl", dropcap: true, locale: "ja"}
      iex> PortfolioWeb.Components.TypographyHelpers.build_class_names(assigns)
      "text-1xl text-deemphasized font-noto-sans-jp bold dropcap"

  """

  # --- Configuration via Module Attributes ---

  @size_classes %{
    "4xl" => "text-4xl",
    "3xl" => "text-3xl",
    "2xl" => "text-2xl",
    "1xl" => "text-1xl",
    "md" => "text-md",
    "1xs" => "text-1xs",
    "2xs" => "text-2xs"
    # Add other sizes as needed
  }

  @color_classes %{
    "main" => "text-main",
    "callout" => "text-callout",
    "deemphasized" => "text-deemphasized",
    "suppressed" => "text-suppressed",
    "accent" => "text-accent"
    # Add other colors as needed
  }

  # Default colors for specific fonts
  @font_default_colors %{
    "cheee" => "deemphasized"
    # Add other font defaults as needed
  }

  # Locale-specific font mappings
  # Fallback logic: specific locale -> "en" -> ""
  @font_variants %{
    "cardinal" => %{
      "en" => "font-cardinal-fruit",
      # Example Japanese equivalent
      "ja" => "font-noto-serif-jp"
    },
    "cheee" => %{
      # Added tracking here as it's font-specific
      "en" => "font-cheee tracking-widest",
      # Example Japanese equivalent
      "ja" => "font-noto-sans-jp bold"
    },
    "flexa" => %{
      "en" => "font-gt-flexa",
      # Example Japanese equivalent
      "ja" => "font-ud-reimin"
    },
    "noto" => %{
      # Noto Sans JP can work for English too
      "en" => "font-noto-sans-jp",
      "ja" => "font-noto-sans-jp"
    }
    # Add other fonts as needed
  }

  # --- Public API ---

  @doc """
  Builds a string of CSS class names based on the provided typography-related options using a pipeline.

  ## Parameters

    - `assigns` - A map containing typography options (see `@moduledoc`).
    - `locale` - An optional explicit locale string. If nil, uses `assigns[:locale]` or `Gettext.get_locale()`.

  ## Returns

    - A string of space-separated CSS class names.
  """
  @spec build_class_names(map(), String.t() | nil) :: String.t()
  def build_class_names(assigns, explicit_locale \\ nil) do
    effective_locale = determine_locale(assigns, explicit_locale)
    font_key = determine_font_key(assigns, effective_locale)

    # Start with an empty list of classes
    []
    |> add_size_class(assigns)
    |> add_color_class(assigns, font_key)
    |> add_font_class(font_key, effective_locale)
    |> add_alignment_class(assigns)
    |> add_dropcap_class(assigns)
    |> add_custom_class(assigns)
    # Filter out empty strings or nils added by helpers
    |> Enum.reject(&(&1 == "" or is_nil(&1)))
    |> Enum.join(" ")
  end

  # --- Private Helper Functions ---

  @doc false
  # Determines the effective locale to use.
  @spec determine_locale(map(), String.t() | nil) :: String.t()
  defp determine_locale(assigns, explicit_locale) do
    explicit_locale || assigns[:locale] || Gettext.get_locale()
  end

  @doc false
  # Determines the font key to use, considering defaults based on locale.
  @spec determine_font_key(map(), String.t()) :: String.t()
  defp determine_font_key(assigns, locale) do
    assigns[:font] || default_font_for_locale(locale)
  end

  @doc false
  # Adds the appropriate size class to the list.
  @spec add_size_class(list(String.t()), map()) :: list(String.t())
  defp add_size_class(classes, assigns) do
    size_key = assigns[:size] || "md"
    # Returns nil if key not found
    size_class = Map.get(@size_classes, size_key)
    # Prepend if found, otherwise keep original list
    if size_class, do: [size_class | classes], else: classes
  end

  @doc false
  # Adds the appropriate color class based on explicit color, font default, or overall default.
  @spec add_color_class(list(String.t()), map(), String.t()) :: list(String.t())
  defp add_color_class(classes, assigns, font_key) do
    color_key =
      assigns[:color] || Map.get(@font_default_colors, font_key) || "main"

    # Returns nil if key not found
    color_class = Map.get(@color_classes, color_key)
    if color_class, do: [color_class | classes], else: classes
  end

  @doc false
  # Adds the appropriate font class based on font key and locale, with fallback.
  @spec add_font_class(list(String.t()), String.t(), String.t()) ::
          list(String.t())
  defp add_font_class(classes, font_key, locale) do
    font_class =
      case Map.get(@font_variants, font_key) do
        # Fallback to 'en'
        %{} = variants -> Map.get(variants, locale, Map.get(variants, "en"))
        # Font key not found in variants
        _ -> nil
      end

    if font_class && font_class != "", do: [font_class | classes], else: classes
  end

  @doc false
  # Adds the text alignment class if centered.
  @spec add_alignment_class(list(String.t()), map()) :: list(String.t())
  defp add_alignment_class(classes, assigns) do
    if Map.get(assigns, :center, false),
      do: ["text-center" | classes],
      else: classes
  end

  @doc false
  # Adds the dropcap class if enabled.
  @spec add_dropcap_class(list(String.t()), map()) :: list(String.t())
  defp add_dropcap_class(classes, assigns) do
    if Map.get(assigns, :dropcap, false),
      do: ["dropcap" | classes],
      else: classes
  end

  @doc false
  # Adds any custom classes provided.
  @spec add_custom_class(list(String.t()), map()) :: list(String.t())
  defp add_custom_class(classes, assigns) do
    custom = assigns[:class]
    if custom && custom != "", do: [custom | classes], else: classes
  end

  @doc false
  # Determines the default font key based on the locale.
  @spec default_font_for_locale(String.t()) :: String.t()
  defp default_font_for_locale(locale) do
    case locale do
      # Default to Noto Sans JP for Japanese
      "ja" -> "noto"
      # Default to GT Flexa for English/others
      _ -> "flexa"
    end
  end
end
