defmodule PortfolioWeb.AboutLive do
  require Logger
  use PortfolioWeb, :live_view
  import PortfolioWeb.LiveHelpers
  alias PortfolioWeb.DevToolbar
  import PortfolioWeb.Components.Typography

  def mount(_params, _session, socket) do
    socket =
      assign_page_metadata(
        socket,
        gettext("About Zane Riley | Product Designer"),
        gettext(
          "Learn more about Zane Riley, a Product Designer with over 10 years of experience in various industries."
        )
      )

    {:ok, socket}
  end

  def handle_params(params, uri, socket) do
    socket = handle_locale_and_path(socket, params, uri)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <.typography tag="p" size="1xl">
        A product designer with over 10 years of experience, currently based in Tokyo and working at Google.
      </.typography>

      <div class="space-y-4">
        <h2 class="text-2xl font-semibold">Experience</h2>
        <div class="space-y-2">
          <p class="font-medium">Google - Senior Product Designer</p>
          <p class="">2018 - Present</p>
        </div>
        <div class="space-y-2">
          <p class="font-medium">NerdWallet - Lead Designer</p>
          <p class="">2015 - 2018</p>
        </div>
      </div>
    </div>
    <div class="aspect-w-1 aspect-h-1 rounded-full overflow-hidden shadow-xl">
      <img src="/images/zane-portrait.jpg" alt="Zane Riley" class="object-cover" />
    </div>
    """
  end
end
