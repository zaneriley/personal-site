defmodule PortfolioWeb.CaseStudyLive.Index do
  use PortfolioWeb, :live_view
  require Logger
  alias Portfolio.Admin
  alias Portfolio.CaseStudy
  import PortfolioWeb.LiveHelpers
  alias PortfolioWeb.Router.Helpers, as: Routes

  @impl true
  def mount(_params, session, socket) do
    env = Mix.env()
    # Extract the locale from the session or default to 'en'
    user_locale =
      session["user_locale"] || Application.get_env(:portfolio, :default_locale)

    Logger.debug("Case study index mounted with locale: #{user_locale}")
    # Stream the case studies and assign the user_locale to the socket
    {:ok,
     socket
     |> assign(:user_locale, user_locale)
     |> assign(:env, env)
     |> stream(:case_studies, Admin.list_case_studies())}
  end

  @impl true
  def handle_params(params, uri, socket) do
    socket = handle_locale_and_path(socket, params, uri)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Case study")
    |> assign(:case_study, Admin.get_case_study!(id))
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
    case_study = Admin.get_case_study!(id)
    {:ok, _} = Admin.delete_case_study(case_study)

    {:noreply, stream_delete(socket, :case_studies, case_study)}
  end
end
