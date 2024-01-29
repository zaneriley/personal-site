defmodule PortfolioWeb.CaseStudyController do
  use PortfolioWeb, :controller
  alias PortfolioWeb.Gettext
  require Logger

  def show(conn, %{"url" => url}) do
    Logger.info("Starting show action in CaseStudyController for URL: #{url}")

    case_study = Portfolio.Content.get_case_study_by_url(url)

    case case_study do
      nil ->
        Logger.error("Case study not found in database for URL: #{url}")
        # Handle the error, e.g., render a 404 page or redirect
      %Portfolio.CaseStudy{title: title, introduction: introduction} ->
        Logger.debug("Case study fetched from the database: #{inspect(case_study)}")

        page_title = "#{title} - " <>
                     gettext("Case Study") <> " | " <>
                     gettext("Zane Riley | Product Design Portfolio")
        Logger.info("Page title set to: #{page_title}")
        Logger.debug("Page description set to: #{introduction}")

        conn
        |> assign(:case_study, case_study)
        |> assign(:page_title, page_title)
        |> assign(:page_description, introduction)
        |> render("show.html", case_study: case_study)
    end
  end
end
