defmodule PortfolioWeb.CaseStudyLive.Show do
  require Logger
  use PortfolioWeb, :live_view
  alias Portfolio.Content
  import PortfolioWeb.LiveHelpers
  import PortfolioWeb.Components.Typography, only: [typography: 1]
  import PortfolioWeb.Components.ContentMetadata

  import Portfolio.Content.Markdown.Renderer, only: [render_to_safe: 1]

  def on_mount(:default, params, session, socket) do
    {:cont,
     PortfolioWeb.LiveHelpers.on_mount(:default, params, session, socket)}
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

    unless valid_slug?(url), do: raise(PortfolioWeb.LiveError)

    case Content.get_with_translations("case_study", url, user_locale) do
      {:ok, case_study, translations, body_ast}
      when is_list(body_ast) ->
        {page_title, introduction} =
          set_page_metadata(case_study, translations)

        {:noreply,
         assign(socket,
           case_study: case_study,
           translations: translations,
           body_ast: body_ast,
           page_title: page_title,
           page_description: introduction
         )}

      {:error, :not_found} ->
        raise PortfolioWeb.LiveError

      {:error, :compilation_failed} ->
        raise "case_study content compilation failed for slug=#{url}, locale=#{user_locale}"
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
