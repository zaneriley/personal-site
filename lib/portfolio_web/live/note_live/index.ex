defmodule PortfolioWeb.NoteLive.Index do
  use PortfolioWeb, :live_view
  require Logger
  alias Portfolio.Blog
  alias Portfolio.Blog.Note

  @impl true
  def mount(_params, session, socket) do
    env = Mix.env()
    # Extract the locale from the session or default to 'en'
    user_locale =
      session["user_locale"] || Application.get_env(:portfolio, :default_locale)

    Logger.debug("Note index mounted with locale: #{user_locale}")
    # Stream the case studies and assign the user_locale to the socket
    {:ok,
     socket
     |> assign(:user_locale, user_locale)
     |> assign(:env, env)
     |> stream(:notes, Blog.list_notes())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Note")
    |> assign(:note, Blog.get_note!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Note")
    |> assign(:note, %Note{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Notes")
    |> assign(:note, nil)
  end

  @impl true
  def handle_info({PortfolioWeb.NoteLive.FormComponent, {:saved, note}}, socket) do
    {:noreply, stream_insert(socket, :notes, note)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    note = Blog.get_note!(id)
    {:ok, _} = Blog.delete_note(note)

    {:noreply, stream_delete(socket, :notes, note)}
  end
end
