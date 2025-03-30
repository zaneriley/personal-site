defmodule Portfolio.Content.Utils.LanguageUtils do
  @moduledoc """
  Utilities for working with languages and locales in the application.

  This module provides helper functions for handling locales, translations,
  and language-specific operations.
  """

  @doc """
  Returns the list of available locales supported by the application.

  ## Returns
    - A list of locale strings (e.g., ["en", "ja"])
  """
  @spec available_locales() :: [String.t()]
  def available_locales do
    ["en", "ja"]
  end

  @doc """
  Returns the default locale for the application.

  ## Returns
    - The default locale string
  """
  @spec default_locale() :: String.t()
  def default_locale do
    Application.get_env(:portfolio, :default_locale, "en")
  end

  @doc """
  Validates if a locale is supported by the application.

  ## Parameters
    - locale: The locale to validate

  ## Returns
    - true if the locale is supported, false otherwise
  """
  @spec valid_locale?(String.t()) :: boolean()
  def valid_locale?(locale) when is_binary(locale) do
    locale in available_locales()
  end

  def valid_locale?(_), do: false
end
