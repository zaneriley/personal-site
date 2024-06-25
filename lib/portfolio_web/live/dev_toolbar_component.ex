defmodule PortfolioWeb.DevToolbar do
  use Phoenix.Component
  import Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div class="z-50 absolute left-0 fixed bottom-0 w-full bg-gray-800 py-2 px-4 border-t border-gray-700 dark:bg-gray-900 dark:text-white dark:border-gray-800">
      <div class="flex flex-col md:flex-row items-center justify-between space-x-4 md:space-x-8">
        <div class="flex space-x-2">
          <div>
            <strong class="text-gray-400 ">ENV:</strong>
            <span class="text-white font-semibold"><%= Mix.env() %></span>
          </div>
          <div>
            <strong class="text-gray-400">LOCALE:</strong>
            <span class="text-white font-semibold"><%= @locale %></span>
          </div>
        </div>

        <div class="mt-2 md:mt-0 space-x-2">
          <div>
            <strong class="text-gray-400">LIVEVIEW:</strong>
            <span class={
              if connected?(@socket),
                do: "text-green-500 font-semibold",
                else: "text-red-500"
            }>
              <%= if connected?(@socket), do: "CONNECTED", else: "DISCONNECTED" %>
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
