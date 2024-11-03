defmodule PortfolioWeb.KitchenSinkLive do
  use Phoenix.LiveView,
    # Set layout to false directly
    layout: false

  import PortfolioWeb.Components.Typography

  # Add collections of strings as module attributes
  @headline_strings [
    {"Memories in the Morning Rain", "朝の雨の中の記憶"},
    {"Whatever Happens, Happens", "なるようになる"},
    {"Rain Station", "雨のステイション"}
  ]

  @large_strings [
    {"In the silence between heartbeats, dreams take flight",
     "心臓の鼓動の間の静けさに、夢が飛び立つ"}
  ]

  @medium_strings [
    {"Like jazz notes floating through an empty room, some thoughts refuse to fade away. They linger, waiting for someone to remember them.",
     "空き部屋に漂うジャズの音のように、消えることを拒む思考がある。誰かに思い出されるのを待ちながら、そこに留まり続ける。"},
    {"A scruffy marmot often finds cactus flowers offtrack. Spectacular mysteries sends stories of doom unraveling. The beetle scuttled across a milkweed leaf, its aeneous body like a golden shield.",
     "深き森で、古代の妖精が琥珀色の光を放っていた。スペースシャトルは銀河の果てへと、無限の夢を運んでゆく。氷結晶の迷宮で、量子の蝶が時空を舞い踊る。"},
    {"On November 7, 2016, debt held by the public was $14.3 trillion or about 76% of the previous 12 months of GDP. Intragovernmental holdings stood at $5.4 trillion, giving a combined total gross national debt of $19.8 trillion or about 106% of the previous 12 months of GDP; $6.2 trillion or approximately 45% of the debt held by the public was owned by foreign investors, the largest of which were Japan and China at about $1.09 trillion for Japan and $1.06 trillion for China as of December 2016.",
     "2016 年 11 月 7 日現在、国民が保有する債務は 14.3 兆ドルで、過去 12 か月の GDP の約 76% を占めています。政府間債務は 5.4 兆ドルで、国民総債務の総額は 19.8 兆ドルで、過去 12 か月の GDP の約 106% を占めています。国民が保有する債務の約 45% にあたる 6.2 兆ドルは外国投資家が保有しており、そのうち最大の国は日本と中国で、2016 年 12 月現在、日本は約 1.09 兆ドル、中国は 1.06 兆ドルとなっています。"}
  ]

  @small_strings [
    {"The clock strikes midnight, but time holds its breath.",
     "時計は真夜中を打つが、時間は息を止めている。"},
    {"See you space cowboy...", "また会おう、スペースカウボーイ..."}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(lang: "en")
     |> assign(show_guides: true)
     |> assign_random_strings()}
  end

  # Add helper function to get random strings
  defp assign_random_strings(socket) do
    assign(socket,
      headline: Enum.random(@headline_strings),
      large: Enum.random(@large_strings),
      medium: Enum.random(@medium_strings),
      small: Enum.random(@small_strings)
    )
  end

  def handle_event("toggle_lang", _, socket) do
    new_lang = if socket.assigns.lang == "en", do: "ja", else: "en"
    {:noreply, assign(socket, lang: new_lang)}
  end

  def handle_event("toggle_guides", _, socket) do
    {:noreply, assign(socket, show_guides: !socket.assigns.show_guides)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-dusk-950" lang={@lang}>
      <div class="sticky top-0 z-50 bg-dusk-900/80 backdrop-blur-sm border-b border-dusk-800 px-4 py-3 mb-8">
        <div class="flex justify-between items-center max-w-[120rem] mx-auto">
          <button
            class="px-3 py-1.5 bg-dusk-800 hover:bg-dusk-700 rounded-md"
            phx-click="toggle_lang"
          >
            <%= if @lang == "en", do: "Switch to 日本語", else: "Switch to English" %>
          </button>
          <button
            class="px-3 py-1.5 bg-dusk-800 hover:bg-dusk-700 rounded-md"
            phx-click="toggle_guides"
          >
            <%= if @show_guides, do: "Hide Guides", else: "Show Guides" %>
          </button>
        </div>
      </div>

      <div class="px-4 max-w-[120rem] mx-auto space-y-16">
        
        <div class="space-y-16">
          <%= for size <- ~w(4xl 2xl 1xl md 1xs) do %>
            <div class="space-y-2">
              
              <div class="relative">
                
                <%= if @show_guides do %>
                  <div class="absolute flex inset-x-0 top-0 w-full h-full pointer-events-none">
                    
                    <div
                      class="absolute inset-x-0 border-t border-blue-500/30 w-full"
                      style="top: 0.75em"
                    >
                    </div>
                    <div
                      class="absolute inset-x-0 border-t border-green-500/30 w-full"
                      style="top: 0.5em"
                    >
                    </div>
                    <div
                      class="absolute inset-x-0 border-t border-red-500/30 w-full"
                      style="top: 1em"
                    >
                    </div>
                  </div>

                  <div class="flex space-x-md text-sm text-dusk-400 font-mono">
                    <.typography tag="span" size="2xs">
                      --fs-<%= size %>
                    </.typography>
                    <.typography tag="span" size="2xs">
                      <%= get_space_value(size) %>
                    </.typography>
                  </div>

                <% end %>

                <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-8">
                  <%= for {font, name} <- [
                      {"cardinal", "Cardinal"},
                      {"cheee", "Cheee"},
                      {"gt-flexa", "GT Flexa"},
                      {nil, "Noto Sans"}
                    ] do %>
                    <div class="bg-dusk-900/30 p-6 rounded-lg relative">
                      <%= if @show_guides do %>
                        
                        <div class="absolute inset-0 pointer-events-none">
                          
                          <div
                            class="absolute inset-x-0 border-t border-blue-500/20 w-full"
                            style={"top: calc(var(--#{font}-small-cap-height) * 1em)"}
                          >
                          </div>
                          <div
                            class="absolute inset-x-0 border-t border-green-500/20 w-full"
                            style={"top: calc(var(--#{font}-small-x-height) * 1em)"}
                          >
                          </div>
                          <div
                            class="absolute inset-x-0 border-t border-red-500/20 w-full"
                            style="top: 1em"
                          >
                          </div>
                        </div>
                      <% end %>

                      <.typography tag="p" size={size} font={font}>
                        <%= if @lang == "en" do %>
                          <%= case size do %>
                            <% size when size in ~w(4xl 2xl) -> %>
                              <%= if @lang == "en",
                                do: elem(@headline, 0),
                                else: elem(@headline, 1) %>
                            <% "1xl" -> %>
                              <%= if @lang == "en",
                                do: elem(@large, 0),
                                else: elem(@large, 1) %>
                            <% "md" -> %>
                              <%= if @lang == "en",
                                do: elem(@medium, 0),
                                else: elem(@medium, 1) %>
                            <% _ -> %>
                              <%= if @lang == "en",
                                do: elem(@small, 0),
                                else: elem(@small, 1) %>
                          <% end %>
                        <% else %>
                          <%= case size do %>
                            <% size when size in ~w(4xl 2xl) -> %>
                              タイポグラフィの世界
                            <% "1xl" -> %>
                              デザインは、丁寧に選ばれた書体を通じて、ブランドの静かな大使として語りかけます。
                            <% "md" -> %>
                              タイポグラフィは、文字を配置する技術であり、読みやすく魅力的な文章表現を実現する芸術です。
                            <% _ -> %>
                              優れたタイポグラフィの本質は、その存在感の無さにあります。読者の目を引くことなく導くべきです。
                          <% end %>
                        <% end %>
                      </.typography>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <section class="bg-dusk-900/30 p-8 rounded-lg">
        <div class="space-y-8">
          <div class="space-y-6">
            <.typography tag="h3" size="1xl">Vertical Spacing</.typography>
            <div class="relative bg-dusk-800/50 p-4">
              <%= for size <- ~w(3xl 2xl 1xl md 1xs) do %>
                <div
                  class="flex items-center gap-4"
                  style={"margin-bottom: var(--space-#{size})"}
                >
                  <code class="text-sm text-dusk-400 font-mono w-24">
                    --space-<%= size %>
                  </code>
                  <div class="flex-1 border-b border-dusk-400/30"></div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </section>
    </div>
    """
  end

  # Helper function to get font metrics
  def get_font_metric(font, metric) do
    case font do
      "cardinal" -> if metric == "cap-height", do: "0.75", else: "0.5"
      "cheee" -> if metric == "cap-height", do: "0.64", else: "0.6"
      "gt-flexa" -> if metric == "cap-height", do: "0.7", else: "0.46"
      _ -> "N/A"
    end
  end

  # Helper function to get space values (you can customize these)
  def get_space_value(size) do
    case size do
      "5xl" -> "clamp(7.59rem, -1.67rem + 46.29vi, 40rem)"
      "4xl" -> "clamp(5.06rem, 0.79rem + 21.34vi, 20rem)"
      "3xl" -> "clamp(3.38rem, 1.48rem + 9.46vi, 10rem)"
      "2xl" -> "clamp(2.25rem, 1.46rem + 3.93vi, 5rem)"
      "1xl" -> "clamp(1.5rem, 1.21rem + 1.43vi, 2.5rem)"
      "md" -> "clamp(1rem, 0.93rem + 0.36vi, 1.25rem)"
      "1xs" -> "clamp(0.63rem, 0.68rem - 0.06vi, 0.67rem)"
      "2xs" -> "clamp(0.31rem, 0.48rem - 0.19vi, 0.44rem)"
      "3xs" -> "clamp(0.16rem, 0.34rem - 0.20vi, 0.30rem)"
    end
  end
end
