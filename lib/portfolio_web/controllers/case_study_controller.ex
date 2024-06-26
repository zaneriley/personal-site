defmodule PortfolioWeb.CaseStudyController do
  use PortfolioWeb, :controller
  alias Portfolio.Content
  require Logger

  def show(conn, %{"url" => url}) do
    if valid_slug?(url) do
      Logger.info("Starting show action in CaseStudyController for URL: #{url}")

      {case_study, translations} =
        Content.get_content_with_translations(
          :case_study,
          url,
          conn.assigns.user_locale
        )

      case case_study do
        nil ->
          Logger.error("Case study not found in database for URL: #{url}")

          conn
          |> put_status(:not_found)
          |> render(PortfolioWeb.ErrorView, "404.html")

        %Portfolio.CaseStudy{} = cs ->
          Logger.info("Case study found for URL: #{url}")

          {page_title, introduction} = set_page_metadata(cs, translations)

          conn
          |> assign(:case_study, cs)
          |> assign(:translations, translations)
          |> assign(:page_title, page_title)
          |> assign(:page_description, introduction)
          |> render("show.html")
      end
    else
      Logger.error("Invalid URL format: #{url}")

      conn
      |> put_status(:bad_request)
      |> render(PortfolioWeb.ErrorView, "400.html")
    end
  end

  defp valid_slug?(slug) do
    Regex.match?(~r/^[a-z0-9-]+$/i, slug)
  end

  defp set_page_metadata(case_study, translations) do
    title = translations["title"] || case_study.title
    introduction = translations["introduction"] || case_study.introduction

    page_title =
      "#{title} - " <>
        gettext("Case Study") <>
        " | " <>
        gettext("Zane Riley | Product Design Portfolio")

    {page_title, introduction}
  end
end
