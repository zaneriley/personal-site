defmodule PortfolioWeb.Components.LanguageSwitch do
  @moduledoc """
  Two fields meeting on an S-curve: EN | 日本語. The current language's field
  is filled.

  It navigates to the same page in the other language, so it is two plain
  links, not a button or a radio group. The curve is one decorative SVG behind
  them; each link is a full-height tap target over its half.
  """
  use Phoenix.Component
  use Gettext, backend: PortfolioWeb.Gettext

  alias PortfolioWeb.Layouts

  attr :current_path, :string, required: true
  attr :current_locale, :string, required: true
  attr :class, :string, default: nil

  @spec language_switch(map()) :: Phoenix.LiveView.Rendered.t()
  def language_switch(assigns) do
    assigns =
      assign(assigns,
        en_path: Layouts.localized_path(assigns.current_path, "en"),
        ja_path: Layouts.localized_path(assigns.current_path, "ja"),
        link_class: "relative flex items-center justify-center text-2xs"
      )

    ~H"""
    <nav
      class={["language-switch", @class]}
      aria-label={gettext("Language switcher")}
    >
      <svg
        viewBox="0 0 112 30"
        preserveAspectRatio="none"
        aria-hidden="true"
        focusable="false"
      >
        <path
          data-current={@current_locale == "en"}
          d="M8 .5H63C53 .5 59 29.5 49 29.5H8Q.5 29.5.5 22V8Q.5.5 8 .5Z"
        />
        <path
          data-current={@current_locale == "ja"}
          d="M63 .5H104Q111.5.5 111.5 8V22Q111.5 29.5 104 29.5H49C59 29.5 53 .5 63 .5Z"
        />
      </svg>
      <a
        class={@link_class}
        href={@en_path}
        lang="en"
        hreflang="en"
        aria-label="English"
        aria-current={if @current_locale == "en", do: "true"}
      >
        EN
      </a>
      <a
        class={@link_class}
        href={@ja_path}
        lang="ja"
        hreflang="ja"
        aria-current={if @current_locale == "ja", do: "true"}
      >
        日本語
      </a>
    </nav>
    """
  end
end
