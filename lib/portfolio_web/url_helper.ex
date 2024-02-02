defmodule PortfolioWeb.UrlHelper do
  @moduledoc """
  Provides helper functions to generate URLs for the portfolio application.
  """

  def case_study_url(locale, case_study_url) do
    "/#{locale}/case-study/#{case_study_url}"
  end
end
