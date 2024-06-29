defmodule PortfolioWeb.NoteLive.Index do
  use PortfolioWeb, :live_view
  require Logger
  alias Portfolio.Blog
  alias Portfolio.Blog.Note
  alias PortfolioWeb.Router.Helpers, as: Routes

  @impl true
  def mount(_params, session, socket) do
    env = Mix.env()
    user_locale = session["user_locale"] || Application.get_env(:portfolio, :default_locale)

    Logger.debug("Note index mounted with locale: #{user_locale}")

    {:ok,
     socket
     |> assign(:user_locale, user_locale)
     |> assign(:env, env)
     |> stream_configure(:notes, dom_id: &"note-#{&1.url}")
     |> stream(:notes, Blog.list_notes())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Note")
    |> assign(:title, "New Note")
    |> assign(:note, %Note{})
  end


  defp apply_action(socket, :edit, %{"url" => url}) do
    socket
    |> assign(:page_title, "Edit Note")
    |> assign(:title, "Edit Note")
    |> assign(:note, Blog.get_note!(url))
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
  def handle_event("delete", %{"url" => url}, socket) do
    note = Blog.get_note!(url)
    {:ok, _} = Blog.delete_note(note)

    {:noreply, stream_delete(socket, :notes, note)}
  end
end
