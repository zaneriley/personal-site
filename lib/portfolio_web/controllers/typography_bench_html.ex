defmodule PortfolioWeb.TypographyBenchHTML do
  @moduledoc false
  use PortfolioWeb, :html

  @stress_cases [
    %{
      id: "stress-edges",
      title: "Outer edges & collisions",
      inspect:
        "Accents above the first cap line; descenders below the last baseline. Check for clipping and collisions between lines.",
      text: "ÅÉÎ HAMBURG 東京
gypqj がぎぐげご
ÅÉÎ HAMBURG 東京
gypqj がぎぐげご"
    },
    %{
      id: "stress-alternate",
      title: "Alternating scripts",
      inspect:
        "Compare the same words on Latin-only, Japanese-only and mixed lines. Watch for baseline jumps or an unexpectedly tall line.",
      text: "Tokyo typography
東京のタイポグラフィ
Tokyo 東京 typography 書体
東京 Tokyo 書体 typography"
    },
    %{
      id: "stress-en",
      title: "English with Japanese",
      inspect:
        "Does a short Japanese phrase disrupt English leading, apparent weight or line endings?",
      text:
        "We call it 余白: space that helps an idea breathe. In Tokyo（東京）, English and 日本語 share a line. Typography should keep its rhythm as the language changes."
    },
    %{
      id: "stress-ja",
      title: "Japanese with English",
      inspect:
        "Watch Latin baseline placement, long English words, and punctuation at narrow line endings.",
      text:
        "東京で「Product design」を考える。余白と typography は、同じ画面のリズムをつくる。Version 2.0 の UI を iPhone で確認し、日本語と English の読みやすさを比べる。"
    },
    %{
      id: "stress-punctuation",
      title: "Brackets & punctuation",
      inspect:
        "Look for stranded opening brackets, closing marks at line starts, and punctuation that appears clipped at the outer edges.",
      text: "「東京（Tokyo）」と『余白』。
“Type,” ‘space’ — café…
【確認】句読点、括弧（日本語）。
終わり。 End! どう見える？"
    },
    %{
      id: "stress-numbers",
      title: "Numbers, units & symbols",
      inspect:
        "Compare fullwidth and proportional figures, minus signs, degree marks and unit alignment.",
      text: "24°C −100°F +0.5°C
２０２６年 9月14日 12:34
¥1,234 / ￥１２３４ / $99.95
100% → ½ × 2 = 1"
    },
    %{
      id: "stress-wrap",
      title: "Difficult wrapping",
      inspect:
        "Deliberately difficult content: distinguish overflow from a trim error. Does the text remain readable at small widths?",
      text: "日本語English日本語English日本語
https://example.com/typography
Internationalization / 国際化
UI・UX・AI — デザインシステム"
    }
  ]

  @spec stress_cases() :: list(map())
  def stress_cases, do: @stress_cases

  @spec specimen(map()) :: Phoenix.LiveView.Rendered.t()
  def specimen(assigns) do
    assigns = assign(assigns, :text, text(assigns.locale, assigns.sample))

    ~H"""
    <!DOCTYPE html>
    <html lang={@locale} data-theme={@theme}>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width,initial-scale=1" />
        <meta name="robots" content="noindex" />
        <link rel="stylesheet" href="/css/app.css" />
        <style>
          body { margin: 0; padding: 24px; background: var(--footer-bg); color: var(--text-color-main); }
          .reading-study { max-inline-size: 38rem; margin-inline: auto; }
          .reading-study header { display: grid; gap: var(--space-md); }
          .reading-study .title-group { display: grid; gap: var(--space-1xs); }
          .reading-study section { margin-block-start: var(--space-2xl); display: grid; gap: var(--space-md); }
          .reading-study .subsection { display: grid; gap: var(--space-1xs); }
          .reading-study figure { margin-block: var(--space-1xl); }
          .reading-study blockquote { border-inline-start: 1px solid var(--accent); padding-inline-start: var(--space-md); }
          .reading-study figcaption { margin-block-start: var(--space-1xs); padding-inline-start: var(--space-md); }
          .reading-study footer { margin-block-start: var(--space-2xl); padding-block-start: var(--space-md); border-top: 1px solid var(--accent); }
          [data-fault="margin"] [data-part="label"] { margin-bottom: 12px; }
          [data-fault="font"] [data-part="text"] { font-family: "Bench Missing Font", monospace !important; }
        </style>
      </head>
      <body data-fault={@fault}>
        <main
          id="specimen"
          data-font={@font}
          data-size={@size}
          data-weight={@weight}
          data-mode={@mode}
          data-sample={@sample}
        >
          <%= if @mode == "weather" do %>
            <PortfolioWeb.Components.Weather.weather snapshot={
              %{
                freshness: :fresh,
                reading: %{
                  temperature_c: 24.0,
                  condition: :partly_cloudy,
                  daylight?: false,
                  reported_at: ~U[2026-09-14 00:00:00Z]
                }
              }
            } />
          <% else %>
            <%= if @mode == "article" do %>
              <.article font={@font} weight={@weight} locale={@locale} />
            <% else %>
              <.typography
                :if={@mode == "stack"}
                tag="p"
                font="mono"
                size="2xs"
                locale={@locale}
                id="label"
                data-part="label"
              >
                Tokyo
              </.typography>
              <.typography
                tag="p"
                font={@font}
                size={@size}
                weight={@weight}
                locale={@locale}
                id="text"
                data-part="text"
              >
                <%= for {line, index} <- Enum.with_index(String.split(@text, "\n")) do %>
                  <br :if={index > 0} />{line}
                <% end %>
              </.typography>
              <.typography
                :if={@mode == "stack"}
                tag="p"
                font="flexa"
                size="3xs"
                locale={@locale}
                id="caption"
                data-part="caption"
              >
                WeatherAPI
              </.typography>
            <% end %>
          <% end %>
        </main>
        <script src="/typography-bench/measure.js">
        </script>
      </body>
    </html>
    """
  end

  attr :font, :string, required: true
  attr :weight, :string, required: true
  attr :locale, :string, required: true

  defp article(assigns) do
    assigns = assign(assigns, :copy, article_copy(assigns.locale))

    ~H"""
    <article class="reading-study">
      <header>
        <div class="title-group">
          <.typography
            tag="p"
            font="mono"
            size="2xs"
            locale={@locale}
            data-part="category"
          >
            {@copy.category}
          </.typography>
          <.typography
            tag="h1"
            font={@font}
            weight={@weight}
            size="4xl"
            locale={@locale}
            data-part="title"
          >
            {@copy.title}
          </.typography>
        </div>
        <.typography
          tag="p"
          font="flexa"
          size="1xl"
          locale={@locale}
          data-part="lede"
        >
          {@copy.lede}
        </.typography>
        <.typography
          tag="p"
          font="mono"
          size="3xs"
          locale={@locale}
          data-part="metadata"
        >
          {@copy.metadata}
        </.typography>
      </header>
      <section aria-labelledby="article-section">
        <.typography
          tag="h2"
          id="article-section"
          font={@font}
          weight={@weight}
          size="2xl"
          locale={@locale}
          data-part="section-heading"
        >
          {@copy.heading}
        </.typography>
        <.typography
          tag="p"
          id="text"
          font="flexa"
          size="md"
          locale={@locale}
          data-part="text"
        >
          {@copy.first}
        </.typography>
        <.typography
          tag="p"
          font="flexa"
          size="md"
          locale={@locale}
          data-part="paragraph"
        >
          {@copy.second}
        </.typography>
      </section>
      <figure>
        <blockquote>
          <.typography
            tag="p"
            font={@font}
            size="1xl"
            locale={@locale}
            data-part="quotation"
          >
            {@copy.quote}
          </.typography>
        </blockquote>
        <figcaption>
          <.typography
            tag="p"
            font="flexa"
            size="1xs"
            locale={@locale}
            data-part="caption"
          >
            {@copy.caption}
          </.typography>
        </figcaption>
      </figure>
      <section aria-labelledby="article-second-section">
        <.typography
          tag="h2"
          id="article-second-section"
          font={@font}
          weight={@weight}
          size="2xl"
          locale={@locale}
          data-part="section-heading"
        >
          {@copy.second_heading}
        </.typography>
        <.typography
          tag="p"
          font="flexa"
          size="md"
          locale={@locale}
          data-part="paragraph"
        >
          {@copy.third}
        </.typography>
        <div class="subsection">
          <.typography
            tag="h3"
            font="flexa"
            size="1xl"
            weight="bold"
            locale={@locale}
            data-part="subheading"
          >
            {@copy.subheading}
          </.typography>
          <.typography
            tag="p"
            font="flexa"
            size="md"
            locale={@locale}
            data-part="paragraph"
          >
            {@copy.fourth}
          </.typography>
        </div>
      </section>
      <footer>
        <.typography
          tag="p"
          font="flexa"
          size="2xs"
          locale={@locale}
          data-part="endnote"
        >
          {@copy.note}
        </.typography>
      </footer>
    </article>
    """
  end

  defp article_copy("ja") do
    %{
      category: "READING STUDY · 読むための余白",
      title: "文字と文字のあいだに",
      lede: "大きな見出しから小さな注釈まで。日本語と English が同じページに並ぶとき、余白はどう感じられるだろう。",
      metadata: "組版サンプル · 2026年9月14日 · 約3分",
      heading: "読む速度が変わる場所",
      first:
        "朝の東京を歩いていると、看板の文字、駅の案内、喫茶店の小さなメニューが目に入る。それぞれの文字は違う速さで読まれる。立ち止まって読む文章もあれば、一瞬だけ目にとまる言葉もある。",
      second:
        "画面の中でも同じことが起こる。Product design という見出しの下に日本語の説明が続く。数字の 24°C や Version 2.0 が入っても、文章のリズムは途切れてほしくない。",
      quote: "「余白は、次の言葉を読むまでの小さな時間。」",
      caption: "組版のための例文 — typography specimen",
      second_heading: "二つの言語、一つのページ",
      third:
        "English と日本語では、文字の輪郭も行の見え方も違う。けれども、見出し、本文、注釈の関係は自然に伝わってほしい。大きさを変えても、同じページの一部として読めるだろうか。",
      subheading: "小さな文字まで確かめる",
      fourth:
        "スマートフォンの狭い画面では、括弧（Tokyo）、句読点、長い英単語の折り返しが目立つ。本文だけでなく、最後の注釈まで無理なく読み進められるかを確かめたい。",
      note:
        "この文章は非公開の組版確認用サンプルです。見出し・本文・引用・注釈の間隔には、サイト共通の spacing tokens を使用しています。"
    }
  end

  defp article_copy(_) do
    %{
      category: "READING STUDY · 読むための余白",
      title: "The space between words",
      lede:
        "From a large heading to a quiet footnote: a reading study for English, 日本語, and the space that holds them together.",
      metadata: "Typography specimen · 14 September 2026 · 3 min",
      heading: "Where the pace changes",
      first:
        "Walking through Tokyo in the morning, you encounter several kinds of reading. A station sign asks for a glance. A café menu invites you to pause. A small notice beside a door waits until you are close enough to see it.",
      second:
        "A page makes similar requests. A heading catches the eye; a paragraph asks you to stay. A phrase such as 余白 — the space around things — briefly changes the texture. The line needs to make room for that change without losing its rhythm.",
      quote: "“Space gives the next thought somewhere to arrive.”",
      caption: "An invented line for this reading study · 組版サンプル",
      second_heading: "Two languages, one page",
      third:
        "English and 日本語 have different silhouettes. Capitals, descenders and full-height characters occupy a line differently. Here they share the same paragraph, alongside everyday details such as 24°C, Version 2.0 and a departure at 12:34.",
      subheading: "Read the small things, too",
      fourth:
        "The smaller text should feel related to the headline without competing with it. On a phone, watch what happens when a long word wraps, when punctuation approaches an edge, or when your eye moves from the quotation back into the main text.",
      note:
        "Private typography specimen. This is sample copy, not a publication draft. Headings, paragraphs, quotations and notes use the site's shared type and spacing tokens."
    }
  end

  defp text(_, "stress-" <> _ = sample) do
    %{text: text} = Enum.find(@stress_cases, &(&1.id == sample))
    text
  end

  defp text("ja", "caps"), do: "東京 日本語 書体"
  defp text("ja", "descenders"), do: "あいうえお がぎぐげご パピプペポ"
  defp text("ja", "punctuation"), do: "「東京」、。！？（日本語）"
  defp text("ja", "mixed"), do: "東京 Tokyo 24°C −100°F gypq"
  defp text("ja", "paragraph"), do: "東京で暮らし、未来のかたちを考える。文字の大きさと行間が読みやすさを変える。"
  defp text(_, "caps"), do: "HAMBURG TOKYO 0123456789"
  defp text(_, "descenders"), do: "Hhx agjpqy ÅÉî gjpqy"
  defp text(_, "punctuation"), do: "‘Type’ — (space), café! 24°C −100°F"
  defp text(_, "mixed"), do: "Tokyo 東京 24°C −100°F gypq"

  defp text(_, "paragraph"),
    do:
      "Thoughtful typography gives each line room to breathe. Small labels, expressive titles, and mixed scripts should remain legible as their containers narrow."
end
