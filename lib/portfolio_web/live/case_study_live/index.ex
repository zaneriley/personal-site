defmodule PortfolioWeb.CaseStudyLive.Index do
  use PortfolioWeb, :live_view

  alias Portfolio.Admin
  alias Portfolio.CaseStudy
  alias PortfolioWeb.Router.Helpers, as: Routes

  @impl true
  def mount(_params, session, socket) do
    # Extract the locale from the session or default to 'en'
    locale = session["locale"] || Application.get_env(:portfolio, :default_locale)

    # Stream the case studies and assign the locale to the socket
    {:ok,
     socket
     |> assign(:locale, locale)
     |> stream(:case_studies, Admin.list_case_studies())}
  end

  @impl true
  def handle_params(params, _url, socket) do
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
