defmodule PortfolioWeb.UrlHelper do
  def case_study_url(locale, case_study_url) do
    "/#{locale}/case-study/#{case_study_url}"
  end
end
