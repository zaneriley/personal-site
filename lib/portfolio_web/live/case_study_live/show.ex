defmodule PortfolioWeb.CaseStudyLive.Show do
  require Logger
  use PortfolioWeb, :live_view
  alias Portfolio.Content
  import PortfolioWeb.LiveHelpers
  alias PortfolioWeb.Router.Helpers, as: Routes
  import PortfolioWeb.Components.Typography, only: [typography: 1]
  import PortfolioWeb.Components.ContentMetadata

  import Portfolio.Content.Markdown.Renderer, only: [render_html: 1]

  @dialyzer {:nowarn_function, mount: 3}
  def on_mount(:default, params, session, socket) do
    {:cont, PortfolioWeb.LiveHelpers.on_mount(:default, params, session, socket)}
  end

  @impl true
  def mount(%{"locale" => user_locale, "url" => url}, _session, socket) do
    if valid_slug?(url) do
      case Content.get_with_translations("case_study", url, user_locale) do
        {:ok, case_study, translations, ast_content}
        when is_list(ast_content) ->
          {page_title, introduction} =
            set_page_metadata(case_study, translations)

          Logger.debug("Case study translations: #{inspect(translations)}")

          {:ok,
           assign(socket,
             case_study: case_study,
             translations: translations,
             ast_content: ast_content,
             compiled_content: nil,
             page_title: page_title,
             page_description: introduction
           )}

        {:ok, case_study, translations, {:error, reason}} ->
          Logger.error("Failed to compile content: #{inspect(reason)}")

          {:ok,
           assign(socket,
             case_study: case_study,
             translations: translations,
             ast_content: nil,
             compiled_content: nil,
             compile_error: reason,
             page_title: case_study.title,
             page_description: case_study.introduction
           )}

        {:error, :not_found} ->
          Logger.error("Case study not found in database for URL: #{url}")
          {:ok, socket, layout: false}
      end
    else
      Logger.error("Invalid URL format: #{url}")
      {:ok, socket, layout: false}
    end
  end

  @impl true
  def mount(_params, session, socket) do
    socket = assign_locale(socket, session)
    {:ok, socket}
  end

  @dialyzer {:nowarn_function, handle_params: 3}
  @dialyzer {:nowarn_function, set_page_metadata: 2}
  @impl true
  def handle_params(
        %{"locale" => user_locale, "url" => url} = params,
        uri,
        socket
      ) do
    socket = handle_locale_and_path(socket, params, uri)

    if valid_slug?(url) do
      case Content.get_with_translations("case_study", url, user_locale) do
        {:ok, case_study, translations, ast_content}
        when is_list(ast_content) ->
          Logger.debug(
            "HELLO! Case study translations: #{inspect(translations)}"
          )

          {page_title, introduction} =
            set_page_metadata(case_study, translations)

          {:noreply,
           assign(socket,
             case_study: case_study,
             translations: translations,
             ast_content: ast_content,
             compiled_content: nil,
             page_title: page_title,
             page_description: introduction
           )}

        {:ok, case_study, translations, {:error, compile_error}} ->
          {page_title, introduction} =
            set_page_metadata(case_study, translations)

          {:noreply,
           assign(socket,
             case_study: case_study,
             translations: translations,
             ast_content: nil,
             compiled_content: nil,
             compile_error: compile_error,
             page_title: page_title,
             page_description: introduction
           )}

        {:error, :not_found} ->
          raise PortfolioWeb.LiveError
      end
    else
      raise PortfolioWeb.LiveError
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

    Logger.debug("Set page title: #{page_title}")
    Logger.debug("Set introduction: #{introduction}")

    {page_title, introduction}
  end
end
