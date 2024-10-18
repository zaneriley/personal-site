defmodule PortfolioWeb.Components.ContentMetadata do
  @moduledoc """
  Provides a component for rendering content metadata such as read time, word count, and updated date.

  This component allows for styling separators independently and handles localization.
  """
  require Logger
  use Phoenix.Component
  import PortfolioWeb.Gettext
  import PortfolioWeb.Components.Typography, only: [typography: 1]
  alias Timex

  # Module attributes for locale-specific formatting
  @japanese_locale "ja"
  @japanese_date_format "%Y年%-m月%-d日"
  @default_date_format "%b %-d, %Y"

  @doc """
  Renders content metadata such as read time, word count, and updated date.

  ## Assigns

    * `:read_time` - The estimated reading time in seconds (integer or string).
    * `:word_count` - The word count of the content (integer or string).
    * `:character_count` - The character count of the content (integer or string).
    * `:updated_at` - The date when the content was last updated (`NaiveDateTime`).
    * `:user_locale` - The locale of the user (string).

  ## Examples

      <.content_metadata read_time={300} word_count={1500} updated_at={~N[2021-10-15 12:34:56]} />

  """
  attr :read_time, :integer, default: nil
  attr :word_count, :integer, default: nil
  attr :character_count, :integer, default: nil
  attr :updated_at, NaiveDateTime, default: nil
  attr :user_locale, :string, default: nil
  @spec content_metadata(map()) :: Phoenix.LiveView.Rendered.t()
  def content_metadata(assigns) do
    assigns = assign_new(assigns, :user_locale, fn -> Gettext.get_locale() end)

    read_time_segment = render_read_time(assigns.read_time)

    word_count_segment =
      render_word_count(assigns.word_count, assigns.user_locale)

    updated_on_segment =
      render_updated_at(assigns.updated_at, assigns.user_locale)

    separator = gettext("Metadata separator")

    ~H"""
    <.typography
      tag="p"
      size="2xs"
      font="cheee"
      color="accent"
      class="flex items-center space-x-1xl"
    >
      <%= if updated_on_segment != "" do %>
        <span><%= updated_on_segment %></span>
      <% end %>

      <%= if read_time_segment != "" or word_count_segment != "" do %>
        <span>
          <%= if read_time_segment != "" do %>
            <span><%= read_time_segment %></span>
          <% end %>

          <%= if read_time_segment != "" and word_count_segment != "" do %>
            <span><%= separator %></span>
          <% end %>

          <%= if word_count_segment != "" do %>
            <span><%= word_count_segment %></span>
          <% end %>
        </span>
      <% end %>
    </.typography>
    """
  end

  @doc false
  # Renders the read time as a localized string.
  @spec render_read_time(nil | integer | String.t()) :: String.t()
  defp render_read_time(nil), do: ""

  defp render_read_time(read_time_seconds) when is_integer(read_time_seconds) do
    read_time_in_minutes = ceil(read_time_seconds / 60)

    if read_time_in_minutes <= 1 do
      gettext("1 min read")
    else
      gettext("%{count} min read", count: read_time_in_minutes)
    end
  end

  defp render_read_time(read_time_seconds) when is_binary(read_time_seconds) do
    case Integer.parse(read_time_seconds) do
      {int_value, ""} -> render_read_time(int_value)
      _ -> ""
    end
  end

  defp render_read_time(_), do: ""

  @doc false
  # Renders the word count as a localized string.
  @spec render_word_count(nil | integer | String.t(), String.t()) :: String.t()
  defp render_word_count(nil, _locale), do: ""

  defp render_word_count(word_count, locale) when is_integer(word_count) do
    formatted_count = format_number_with_delimiter(word_count, locale)

    ngettext("%{formatted_count} word", "%{formatted_count} words", word_count,
      formatted_count: formatted_count
    )
  end

  defp render_word_count(word_count, locale) when is_binary(word_count) do
    case Integer.parse(word_count) do
      {int_value, ""} -> render_word_count(int_value, locale)
      _ -> ""
    end
  end

  defp render_word_count(_, _locale), do: ""

  @doc false
  # Renders the updated date as a localized string.
  @spec render_updated_at(nil | NaiveDateTime.t(), String.t()) :: String.t()
  defp render_updated_at(nil, _locale), do: ""

  defp render_updated_at(updated_at, locale) do
    today = Timex.today()
    updated_date = Timex.to_date(updated_at)
    formatted_date = format_date(updated_at, locale)

    cond do
      Timex.compare(updated_date, today) == 0 ->
        gettext("Updated today")

      Timex.compare(updated_date, Timex.shift(today, days: -1)) == 0 ->
        gettext("Updated yesterday")

      true ->
        gettext("Updated %{date}", date: formatted_date)
    end
  end

  @doc false
  # Formats a number with delimiters based on the locale.
  @spec format_number_with_delimiter(integer(), String.t()) :: String.t()
  defp format_number_with_delimiter(number, _locale) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  @doc false
  # Formats a date based on the locale.
  @spec format_date(NaiveDateTime.t(), String.t()) :: String.t()
  defp format_date(date, locale) do
    format_string =
      case locale do
        @japanese_locale -> @japanese_date_format
        _ -> @default_date_format
      end

    Timex.format!(date, format_string, :strftime)
  end
end
