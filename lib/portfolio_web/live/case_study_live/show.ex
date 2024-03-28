defmodule PortfolioWeb.CaseStudyLive.Show do
  use PortfolioWeb, :live_view

  alias Portfolio.Admin

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:case_study, Admin.get_case_study!(id))}
  end

  defp page_title(:show), do: "Show Case study"
  defp page_title(:edit), do: "Edit Case study"
end
