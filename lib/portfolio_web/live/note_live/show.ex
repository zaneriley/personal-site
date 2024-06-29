defmodule PortfolioWeb.NoteLive.Show do
  use PortfolioWeb, :live_view
  alias PortfolioWeb.Router.Helpers, as: Routes
  alias Portfolio.Blog

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"url" => url}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:title, page_title(socket.assigns.live_action))
     |> assign(:note, Blog.get_note!(url))}
  end

  defp page_title(:show), do: "Show Note"
  defp page_title(:edit), do: "Edit Note"
end
