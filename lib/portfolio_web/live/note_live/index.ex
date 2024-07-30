defmodule PortfolioWeb.NoteLive.Index do
  use PortfolioWeb, :live_view
  require Logger
  import PortfolioWeb.LiveHelpers
  alias Portfolio.Content
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Content.Entry
  alias PortfolioWeb.Router.Helpers, as: Routes

  @impl true
  def mount(_params, session, socket) do
    env = Application.get_env(:portfolio, :environment)

    user_locale =
      session["user_locale"] || Application.get_env(:portfolio, :default_locale)

    Logger.debug("Note index mounted with locale: #{user_locale}")

    {:ok,
     socket
     |> assign(:user_locale, user_locale)
     |> assign(:env, env)
     |> stream_configure(:notes, dom_id: &"note-#{&1.url}")
     |> stream(:notes, Content.list("note"))}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket = handle_locale_and_path(socket, params, uri)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Note")
    |> assign(:title, "New Note")
    |> assign(:note, %Note{})
  end

  defp apply_action(socket, :edit, %{"url" => url}) do
    note = Content.get!("note", url)

    socket
    |> assign(:page_title, "Edit Note")
    |> assign(:title, "Edit Note")
    |> assign(:note, note)
  end


  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Notes")
    |> assign(:title, "Listing Notes")
    |> assign(:note, nil)
  end

  @impl true
  def handle_info({PortfolioWeb.NoteLive.FormComponent, {:saved, note}}, socket) do
    {:noreply, stream_insert(socket, :notes, note)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    try do
      note = Content.get!("note", id)

      case Content.delete("note", note) do
        {:ok, _} ->
          {:noreply, stream_delete(socket, :notes, note)}

        {:error, reason} ->
          {:noreply,
           put_flash(
             socket,
             :error,
             "Failed to delete note: #{inspect(reason)}"
           )}
      end
    rescue
      Ecto.NoResultsError ->
        {:noreply, put_flash(socket, :error, "Note not found")}

      e in [
        Portfolio.Content.ContentTypeMismatchError,
        Portfolio.Content.InvalidContentTypeError
      ] ->
        {:noreply, put_flash(socket, :error, e.message)}

      e ->
        require Logger
        Logger.error("Unexpected error while deleting note: #{inspect(e)}")
        {:noreply, put_flash(socket, :error, "An unexpected error occurred")}
    end
  end
end
