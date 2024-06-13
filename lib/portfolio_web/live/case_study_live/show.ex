defmodule PortfolioWeb.CaseStudyLive.Show do
  require Logger
  use PortfolioWeb, :live_view
  alias Portfolio.Content
  alias PortfolioWeb.Router.Helpers, as: Routes

  @impl true
  def mount(%{"url" => url}, session, socket) do
    user_locale = session["user_locale"] || Application.get_env(:portfolio, :default_locale)
    Logger.info("Locale for CaseStudyLive.Show: #{user_locale}")
    if valid_slug?(url) do
      {case_study, translations} = Content.get_content_with_translations(:case_study, url, user_locale)

      case case_study do
        nil ->
          Logger.error("Case study not found in database for URL: #{url}")
          {:ok, socket |> put_flash(:error, "Case study not found") |> redirect(to: "/")}

        %Portfolio.CaseStudy{} = cs ->
          {page_title, introduction} = set_page_metadata(cs, translations)
          {:ok, assign(socket, case_study: cs, translations: translations, page_title: page_title, page_description: introduction, user_locale: user_locale)}
      end
    else
      Logger.error("Invalid URL format: #{url}")
      {:ok, socket |> put_flash(:error, "Invalid URL") |> redirect(to: "/")}
    end
  end

  @impl true
  def handle_params(%{"url" => _url}, _, socket) do
    {:noreply, socket}
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
