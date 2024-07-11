defmodule PortfolioWeb.AboutLive do
  require Logger
  use PortfolioWeb, :live_view
  import PortfolioWeb.LiveHelpers
  alias PortfolioWeb.DevToolbar

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
    # Add any view-specific logic here
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <main class="u-container">
      <%= if Application.get_env(:portfolio, :environment) == :dev do %>
        <div>
          Debug: Gettext Locale: <%= Gettext.get_locale(PortfolioWeb.Gettext) %>,
          Assign Locale: <%= @user_locale %>
        </div>
        <DevToolbar.render socket={@socket} locale={@user_locale} />
      <% end %>
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-16 sm:py-24">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div class="space-y-8">
            <h1 class="text-4xl sm:text-5xl font-bold leading-tight">
              Hi, I'm Zane Riley
            </h1>
            <p class="text-xl">
              A product designer with over 10 years of experience, currently based in Tokyo and working at Google.
            </p>
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
          <div class="relative">
            <div class="aspect-w-1 aspect-h-1 rounded-full overflow-hidden shadow-xl">
              <img
                src="/images/zane-portrait.jpg"
                alt="Zane Riley"
                class="object-cover"
              />
            </div>
            <div class="absolute -bottom-4 -right-4 bg-space-color-4 text-white p-4 rounded-lg shadow-lg">
              <p class="font-medium">Let's connect</p>
              <a
                href="mailto:zane@example.com"
                class="text-space-color-1 hover:underline"
              >
                zane@example.com
              </a>
            </div>
          </div>
        </div>
      </div>
    </main>
    """
  end
end
