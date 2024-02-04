defmodule PortfolioWeb.CaseStudyController do
  use PortfolioWeb, :controller
  alias Portfolio.Content
  require Logger

  def show(conn, %{"url" => url}) do
    Logger.info("Starting show action in CaseStudyController for URL: #{url}")

    # Use the correct function from the Content context module
    {case_study, translations} =
      Content.get_content_with_translations(
        :case_study,
        url,
        conn.assigns.user_locale
      )

    {page_title, introduction} = set_page_metadata(case_study, translations)

    case case_study do
      nil ->
        Logger.error("Case study not found in database for URL: #{url}")

        conn
        |> assign(:case_study, case_study)
        |> assign(:translations, translations)
        |> assign(:page_title, "Not Found")
        |> assign(:page_description, "The requested case study was not found.")
        |> render("error.html")

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

  end

  # Moved out of the show/2 function
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
