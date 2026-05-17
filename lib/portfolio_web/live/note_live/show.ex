# lib/portfolio_web/live/note_live/show.ex
defmodule PortfolioWeb.NoteLive.Show do
  use PortfolioWeb, :live_view
  alias Portfolio.Content
  alias PortfolioWeb.ShareMetadata
  import PortfolioWeb.LiveHelpers, only: [handle_locale_and_path: 3]
  require Logger
  import PortfolioWeb.Components.Typography
  import Portfolio.Content.Markdown.Renderer, only: [render_to_safe: 1]

  @impl true
  def mount(%{"locale" => user_locale}, _session, socket) do
    Gettext.put_locale(PortfolioWeb.Gettext, user_locale)
    {:ok, assign(socket, user_locale: user_locale)}
  end

  @impl true
  def handle_params(%{"url" => url} = params, uri, socket) do
    socket = handle_locale_and_path(socket, params, uri)

    case Content.get_with_translations("note", url, socket.assigns.user_locale) do
      {:ok, note, translations, body_ast} ->
        {page_title, introduction} = set_page_metadata(note, translations)
        share_meta = build_share_metadata(socket, note, translations)
        Logger.debug("Note translations: #{inspect(translations)}")

        {:noreply,
         assign(socket,
           note: note,
           translations: translations,
           body_ast: body_ast,
           page_title: page_title,
           page_description: introduction,
           share_metadata: share_meta
         )}

      {:error, :not_found} ->
        raise PortfolioWeb.LiveError

      {:error, :compilation_failed} ->
        raise "note content compilation failed for slug=#{url}, locale=#{socket.assigns.user_locale}"
    end
  end

  defp set_page_metadata(note, translations) do
    title = translations["title"] || note.title
    introduction = translations["introduction"] || note.introduction

    page_title =
      "#{title} - " <>
        gettext("Note") <>
        " | " <>
        gettext("Zane Riley | Product Design Portfolio")

    Logger.debug("Set page title: #{page_title}")
    Logger.debug("Set introduction: #{introduction}")

    {page_title, introduction}
  end

  defp build_share_metadata(socket, note, translations) do
    share_title =
      translations["share_title"] || note.share_title ||
        translations["title"] || note.title

    share_description =
      translations["share_description"] || note.share_description ||
        translations["introduction"] || note.introduction ||
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
