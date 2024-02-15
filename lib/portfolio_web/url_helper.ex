defmodule PortfolioWeb.UrlHelper do
  @moduledoc """
  Provides helper functions to generate URLs for the portfolio application.
  """

  def case_study_url(locale, case_study_url) do
    "/#{locale}/case-study/#{case_study_url}"
  end

  def current_page_url(conn, locale) do
    # Get the current path and params
    current_path = conn.request_path
    current_params = conn.params

    case current_path do
      "/case-study/" <> case_study_slug ->
        case_study_url(locale, case_study_slug)

      _ ->
        # Handle other types of URLs or default to a generic structure
        "#{current_path}"
    end
  end
end
