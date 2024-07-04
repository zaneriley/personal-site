defmodule PortfolioWeb.CaseStudyLive.Show do
  require Logger
  use PortfolioWeb, :live_view
  alias Portfolio.Content
  import PortfolioWeb.LiveHelpers
  alias PortfolioWeb.Router.Helpers, as: Routes
  alias PortfolioWeb.DevToolbar

  @impl true
  def mount(%{"locale" => user_locale, "url" => url}, _session, socket) do
    Gettext.put_locale(PortfolioWeb.Gettext, user_locale)

    if valid_slug?(url) do
      {case_study, translations} =
        Content.get_content_with_translations(:case_study, url, user_locale)

      case case_study do
        nil ->
          Logger.error("Case study not found in database for URL: #{url}")

          raise Phoenix.Router.NoRouteError,
            conn: socket,
            router: PortfolioWeb.Router

        %Portfolio.CaseStudy{} = cs ->
          # Logger.debug("Case study: #{inspect(cs, pretty: true)}")
          # Logger.debug("Translations: #{inspect(translations, pretty: true)}")

          {page_title, introduction} = set_page_metadata(cs, translations)

          {:ok,
           assign(socket,
             case_study: cs,
             translations: translations,
             page_title: page_title,
             page_description: introduction,
             user_locale: user_locale
           )}
      end
    else
      Logger.error("Invalid URL format: #{url}")

      raise Phoenix.Router.NoRouteError,
        conn: socket,
        router: PortfolioWeb.Router
    end
  end

  @impl true
  def mount(_params, session, socket) do
    socket = assign_locale(socket, session)
    {:ok, socket}
  end

  @impl true
  def handle_params(
        %{"locale" => user_locale, "url" => url} = params,
        uri,
        socket
      ) do
    socket = handle_locale_and_path(socket, params, uri)

    if valid_slug?(url) do
      {case_study, translations} =
        Content.get_content_with_translations(:case_study, url, user_locale)

      case case_study do
        nil ->
          raise Phoenix.Router.NoRouteError,
            conn: socket,
            router: PortfolioWeb.Router

        %Portfolio.CaseStudy{} = cs ->
          {page_title, introduction} = set_page_metadata(cs, translations)

          {:noreply,
           assign(socket,
             case_study: cs,
             translations: translations,
             page_title: page_title,
             page_description: introduction
           )}
      end
    else
      raise Phoenix.Router.NoRouteError,
        conn: socket,
        router: PortfolioWeb.Router
    end
  end

  defp valid_slug?(slug) do
    Regex.match?(~r/^[a-z0-9-]+$/i, slug)
  end

  defp set_page_metadata(case_study, translations) do
    title = translations[:title] || case_study.title
    introduction = translations[:introduction] || case_study.introduction

    page_title =
      "#{title} - " <>
        gettext("Case Study") <>
        " | " <>
        gettext("Zane Riley | Product Design Portfolio")

    Logger.debug("Set page title: #{page_title}")
    Logger.debug("Set introduction: #{introduction}")

    {page_title, introduction}
  end
end
