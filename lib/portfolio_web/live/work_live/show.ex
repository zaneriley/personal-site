defmodule PortfolioWeb.WorkLive.Show do
  require Logger
  use PortfolioWeb, :live_view
  alias Portfolio.Content
  alias PortfolioWeb.ShareMetadata
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

    case Content.get_with_translations("project", url, user_locale) do
      {:ok, project, translations, body_ast}
      when is_list(body_ast) ->
        {page_title, introduction} =
          set_page_metadata(project, translations)

        share_meta = build_share_metadata(socket, project, translations)

        {:noreply,
         assign(socket,
           project: project,
           translations: translations,
           body_ast: body_ast,
           page_title: page_title,
           page_description: introduction,
           share_metadata: share_meta
         )}

      {:error, :not_found} ->
        raise PortfolioWeb.LiveError

      {:error, :compilation_failed} ->
        raise "project content compilation failed for slug=#{url}, locale=#{user_locale}"
    end
  end

  defp valid_slug?(slug) do
    Regex.match?(~r/^[a-z0-9-]+$/i, slug)
  end

  defp set_page_metadata(project, translations) do
    title = translations["title"] || project.title
    introduction = translations["introduction"] || project.introduction

    page_title =
      gettext("Product design case study") <>
        ": #{title} | " <>
        gettext("Zane Riley | Product Design Portfolio")

    Logger.debug("Set page title: #{page_title}")
    Logger.debug("Set introduction: #{introduction}")

    {page_title, introduction}
  end

  defp build_share_metadata(socket, project, translations) do
    share_title =
      translations["share_title"] || project.share_title ||
        translations["title"] || project.title

    share_description =
      translations["share_description"] || project.share_description ||
        translations["introduction"] || project.introduction ||
        socket.assigns.page_description

    ShareMetadata.build(
      title: share_title,
      description: share_description,
      type: "article",
      locale: socket.assigns.user_locale,
      path: socket.assigns.current_path
    )
  end
end
