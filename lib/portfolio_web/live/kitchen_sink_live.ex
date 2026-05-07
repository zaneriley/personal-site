defmodule PortfolioWeb.KitchenSinkLive do
  use Phoenix.LiveView,
    # Set layout to false directly
    layout: false

  import PortfolioWeb.Components.Typography
  import Phoenix.HTML, only: [raw: 1]

  @palettes [
    %{
      id: :space_cowboy,
      weight: 1,
      strings: %{
        headline: {"Whatever Happens, Happens", "なるようになる"},
        large:
          {"In the silence between heartbeats, dreams take flight",
           "心臓の鼓動の間の静けさに、夢が飛び立つ"},
        medium:
          {"Like jazz notes floating through an empty room, some thoughts refuse to fade away. They linger, waiting for someone to remember them.",
           "空き部屋に漂うジャズの音のように、消えることを拒む思考がある。誰かに思い出されるのを待ちながら、そこに留まり続ける。"},
        small: {"See you space cowboy...", "また会おう、スペースカウボーイ..."}
      }
    },
    %{
      id: :memories,
      weight: 1,
      strings: %{
        headline: {"Memories in the Morning", "朝の雨の中の記憶"},
        large:
          {"A scruffy marmot often finds cactus flowers offtrack. Spectacular mysteries sends stories of doom unraveling. The beetle scuttled across a milkweed leaf, its aeneous body like a golden shield.",
           "深き森で、古代の妖精が琥珀色の光を放っていた。スペースシャトルは銀河の果てへと、無限の夢を運んでゆく。氷結晶の迷宮で、量子の蝶が時空を舞い踊る。"},
        medium:
          {"A scruffy marmot often finds cactus flowers offtrack. Spectacular mysteries sends stories of doom unraveling. The beetle scuttled across a milkweed leaf, its aeneous body like a golden shield.",
           "深き森で、古代の妖精が琥珀色の光を放っていた。スペースシャトルは銀河の果てへと、無限の夢を運んでゆく。氷結晶の迷宮で、量子の蝶が時空を舞い踊る。"},
        small:
          {"I saw my breath dancing in the cold damp air. In this new universe, dust particles and time melt into an ashen residue as red and brown kites float by. He always told me to chase my truest joy, and sometimes, at the time, I didn't know if I'd done that.",
           "冷たく湿った空気の中で、自分の息が踊っているのが見えた。この新しい宇宙では、赤や茶色の凧が舞い、塵の粒子と時間が溶けて灰の残滓になる。父はいつも私に、自分の本当の喜びを追い求めなさいと言っていたが、その時は、自分がそれを成し遂げたかどうかわからなかったこともあった。"}
      }
    },
    %{
      id: :rain_station,
      weight: 1,
      strings: %{
        headline: {"Rain Station", "雨のステイション"},
        large: {"Yumi Arai", "荒井由実"},
        medium: {"For Someone New
        Don't remember someone like me
        Don't remember me for someone new
        Those words that couldn't even become a voice
        Seasons carry them away into the distance of time
        June is hazily blue
        Blurring everything", "新しい誰かのために
        わたしなど 思い出さないで声にさえもならなかった あのひと言を
        季節は運んでく 時の彼方
        六月は蒼く煙って
        なにもかもにじませている"},
        small:
          {"The clock strikes midnight, but time holds its breath.",
           "時計は真夜中を打つが、時間は息を止めている。"}
      }
    },
    %{
      id: :hiraeth,
      weight: 1,
      strings: %{
        headline: {"Hiraeth", "ヒレース"},
        large:
          {"The rise and fall reminds us of what is lost. Strawberries bloom and despite the melancholy, everything is iridescent, disappearing behind our hands. It's twilight in an abandoned place of faded memories, flourishing between the cracks. Clouds billow from galaxies far away and a lone traveler keeps a watchful eye.",
           "上り下りは、失われたものを私たちに思い出させます。 苺が咲き乱れ、哀愁を忘れ、すべてが虹色に輝いて、私たちの手の平へと溶けていきます。 左りゆく月が私たちを微睡ませ、遠い創造・成長の時代は滅びの一前へと更に前進します。遥かなる命、次から次へと蓄積しまみた雪は微笑みを引き起こし、それによって繋いでいます。"},
        medium:
          {"The rise and fall reminds us of what is lost. Strawberries bloom and despite the melancholy, everything is iridescent, disappearing behind our hands. It's twilight in an abandoned place of faded memories, flourishing between the cracks. Clouds billow from galaxies far away and a lone traveler keeps a watchful eye.",
           "上り下りは、失われたものを私たちに思い出させます。 苺が咲き乱れ、哀愁を忘れ、すべてが虹色に輝いて、私たちの手の平へと溶けていきます。 左りゆく月が私たちを微睡ませ、遠い創造・成長の時代は滅びの一前へと更に前進します。遥かなる命、次から次へと蓄積しまみた雪は微笑みを引き起こし、それによって繋いでいます。"},
        small:
          {"Trees crackle and sway beneath the weight of snowdrifts. A lone traveler surveys the scene, searching for lost memories. With longing hearts, we watch the clouds move in. It's twilight in an abandoned place of faded memories, flourishing between the cracks.",
           "雪深さの下で木々は擦られ踊り回ります。ひとりの旅人が群青を超えて、幽霊の記憶をみつけるまで策勢します。私たちは思いがけない赦しを受け入れています。"}
      }
    }
  ]

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(lang: "en")
     |> assign(show_guides: true)
     |> assign(previous_palette_id: nil)
     |> assign_random_palette()}
  end

  # New helper functions
  defp assign_random_palette(socket) do
    current_id = socket.assigns[:current_palette_id]

    # Create weighted list of palette IDs
    weighted_ids =
      Enum.flat_map(@palettes, fn %{id: id, weight: weight} ->
        List.duplicate(id, weight)
      end)

    # Remove current ID from selection pool
    available_ids = Enum.reject(weighted_ids, &(&1 == current_id))

    # Select new random palette
    new_id = Enum.random(available_ids)
    new_palette = Enum.find(@palettes, &(&1.id == new_id))

    socket
    |> assign(current_palette_id: new_id)
    |> assign(previous_palette_id: current_id)
    |> assign(current_palette: new_palette.strings)
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
            {if @lang == "en", do: "Switch to 日本語", else: "Switch to English"}
          </button>
          <button
            class="px-3 py-1.5 bg-dusk-800 hover:bg-dusk-700 rounded-md"
            phx-click="toggle_guides"
          >
            {if @show_guides, do: "Hide Guides", else: "Show Guides"}
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
                    <.typography locale={@user_locale} tag="span" size="2xs">
                      --fs-{size}
                    </.typography>
                    <.typography locale={@user_locale} tag="span" size="2xs">
                      {get_space_value(size)}
                    </.typography>
                  </div>
                <% end %>

                <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-8">
                  <%= for {font, _name} <- [
                      {"cheee", "Cheee"},
                      {"cardinal", "Cardinal"},
                      {"gt-flexa", "GT Flexa"},
                      {"noto", "Noto Sans JP"}
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

                      <.typography
                        locale={@user_locale}
                        tag="p"
                        size={size}
                        font={font}
                      >
                        <%= if font == "noto" do %>
                          <%= case size do %>
                            <% size when size in ~w(4xl 2xl) -> %>
                              {process_text(elem(@current_palette.headline, 1))}
                            <% "1xl" -> %>
                              {process_text(elem(@current_palette.large, 1))}
                            <% "md" -> %>
                              {process_text(elem(@current_palette.medium, 1))}
                            <% _ -> %>
                              {process_text(elem(@current_palette.small, 1))}
                          <% end %>
                        <% else %>
                          <%= if @lang == "en" do %>
                            <%= case size do %>
                              <% size when size in ~w(4xl 2xl) -> %>
                                {process_text(elem(@current_palette.headline, 0))}
                              <% "1xl" -> %>
                                {process_text(elem(@current_palette.large, 0))}
                              <% "md" -> %>
                                {process_text(elem(@current_palette.medium, 0))}
                              <% _ -> %>
                                {process_text(elem(@current_palette.small, 0))}
                            <% end %>
                          <% else %>
                            <%= case size do %>
                              <% size when size in ~w(4xl 2xl) -> %>
                                {process_text(elem(@current_palette.headline, 1))}
                              <% "1xl" -> %>
                                {process_text(elem(@current_palette.large, 1))}
                              <% "md" -> %>
                                {process_text(elem(@current_palette.medium, 1))}
                              <% _ -> %>
                                {process_text(elem(@current_palette.small, 1))}
                            <% end %>
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
                    --space-{size}
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
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
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

  defp process_text(text) when is_binary(text) do
    # Convert \n to <br> and handle existing <br> tags
    text
    |> String.replace("\n", "<br>")
    |> raw()
  end
end
