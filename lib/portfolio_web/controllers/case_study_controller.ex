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

    case case_study do
      nil ->
        Logger.error("Case study not found in database for URL: #{url}")

      # Handle the error, e.g., render a 404 page or redirect
      case_study ->
        # Use translations to get the title and introduction
        title = translations["title"] || case_study.title
        introduction = translations["introduction"] || case_study.introduction

        page_title =
          "#{title} - " <>
            gettext("Case Study") <>
            " | " <>
            gettext("Zane Riley | Product Design Portfolio")

        Logger.info("Page title set to: #{page_title}")
        Logger.debug("Page description set to: #{introduction}")

        conn
        |> assign(:case_study, case_study)
        |> assign(:translations, translations)
        |> assign(:page_title, page_title)
        |> assign(:page_description, introduction)
        |> render("show.html")
    end
  end
end
