defmodule PortfolioWeb.WorkLive.Index do
  use PortfolioWeb, :live_view
  require Logger
  alias Portfolio.Content
  alias Portfolio.Content.Schemas.Project
  import PortfolioWeb.LiveHelpers
  import PortfolioWeb.Components.PortfolioItemList

  def on_mount(:default, params, session, socket) do
    {:cont,
     PortfolioWeb.LiveHelpers.on_mount(:default, params, session, socket)}
  end

  @impl true
  def mount(_params, _session, socket) do
    env = Application.get_env(:portfolio, :environment)

    Logger.debug(
      "Project index mounted with locale: #{socket.assigns.user_locale}"
    )

    projects = Content.list("project", [], socket.assigns.user_locale)

    {:ok,
     socket
     |> assign(:env, env)
     |> stream(:projects, projects)}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket = handle_locale_and_path(socket, params, uri)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"url" => _url}) do
    projects = Content.list("project", [], socket.assigns.user_locale)

    socket
    |> assign(:page_title, "Listing Projects")
    |> assign(:project, nil)
    |> stream(:projects, projects)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Project")
    |> assign(:project, %Project{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Projects")
    |> assign(:project, nil)
  end

  @impl true
  def handle_info(
        {PortfolioWeb.WorkLive.FormComponent, {:saved, project}},
        socket
      ) do
    {:noreply, stream_insert(socket, :projects, project)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    try do
      project = Content.get!("project", id)

      case Content.delete("project", project) do
        {:ok, _} ->
          {:noreply, stream_delete(socket, :projects, project)}

        {:error, reason} ->
          {:noreply,
           put_flash(
             socket,
             :error,
             "Failed to delete project: #{inspect(reason)}"
           )}
      end
    rescue
      Ecto.NoResultsError ->
        {:noreply, put_flash(socket, :error, "Project not found")}

      e in Portfolio.Content.InvalidContentTypeError ->
        {:noreply, put_flash(socket, :error, e.message)}

      e ->
        require Logger

        Logger.error("Unexpected error while deleting project: #{inspect(e)}")

        {:noreply, put_flash(socket, :error, "An unexpected error occurred")}
    end
  end
end
