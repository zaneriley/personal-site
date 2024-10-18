defmodule PortfolioWeb.CaseStudyLive.Index do
  use PortfolioWeb, :live_view
  require Logger
  alias Portfolio.Content
  alias Portfolio.Content.Schemas.CaseStudy
  import PortfolioWeb.LiveHelpers
  alias PortfolioWeb.Router.Helpers, as: Routes
  import PortfolioWeb.Components.PortfolioItemList

  @impl true
  def mount(_params, session, socket) do
    env = Application.get_env(:portfolio, :environment)

    user_locale =
      session["user_locale"] || Application.get_env(:portfolio, :default_locale)

    Logger.debug("Case study index mounted with locale: #{user_locale}")

    case_studies = Content.list("case_study", [], user_locale)

    {:ok,
     socket
     |> assign(:user_locale, user_locale)
     |> assign(:env, env)
     |> stream(:case_studies, case_studies)}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket = handle_locale_and_path(socket, params, uri)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"url" => url}) do
    case_studies = Content.list("case_study", [], socket.assigns.user_locale)

    socket
    |> assign(:page_title, "Listing Case studies")
    |> assign(:case_study, nil)
    |> stream(:case_studies, case_studies)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Case study")
    |> assign(:case_study, %CaseStudy{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Case studies")
    |> assign(:case_study, nil)
  end

  @impl true
  def handle_info(
        {PortfolioWeb.CaseStudyLive.FormComponent, {:saved, case_study}},
        socket
      ) do
    {:noreply, stream_insert(socket, :case_studies, case_study)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    try do
      case_study = Content.get!("case_study", id)

      case Content.delete("case_study", case_study) do
        {:ok, _} ->
          {:noreply, stream_delete(socket, :case_studies, case_study)}

        {:error, reason} ->
          {:noreply,
           put_flash(
             socket,
             :error,
             "Failed to delete case study: #{inspect(reason)}"
           )}
      end
    rescue
      Ecto.NoResultsError ->
        {:noreply, put_flash(socket, :error, "Case study not found")}

      e in [
        Portfolio.Content.ContentTypeMismatchError,
        Portfolio.Content.InvalidContentTypeError
      ] ->
        {:noreply, put_flash(socket, :error, e.message)}

      e ->
        require Logger

        Logger.error(
          "Unexpected error while deleting case study: #{inspect(e)}"
        )

        {:noreply, put_flash(socket, :error, "An unexpected error occurred")}
    end
  end
end
