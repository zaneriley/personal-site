# lib/portfolio_web/live/note_live/show.ex
defmodule PortfolioWeb.NoteLive.Show do
  use PortfolioWeb, :live_view
  alias PortfolioWeb.Router.Helpers, as: Routes
  alias Portfolio.Content
  require Logger

  @impl true
  def mount(%{"locale" => user_locale}, _session, socket) do
    Gettext.put_locale(PortfolioWeb.Gettext, user_locale)
    {:ok, assign(socket, user_locale: user_locale)}
  end

  @impl true
  def handle_params(%{"url" => url}, _, socket) do
    case Content.get_with_translations("note", url, socket.assigns.user_locale) do
      {:ok, note, translations} ->
        {page_title, introduction} = set_page_metadata(note, translations)
        Logger.debug("Note translations: #{inspect(translations)}")

        {:noreply,
         assign(socket,
           note: note,
           translations: translations,
           page_title: page_title,
           page_description: introduction
         )}

      {:error, :not_found} ->
        raise Phoenix.Router.NoRouteError,
          conn: socket,
          router: PortfolioWeb.Router
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
end
