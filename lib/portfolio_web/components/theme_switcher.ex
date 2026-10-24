defmodule PortfolioWeb.Components.ThemeSwitcher do
  @moduledoc """
  A binary sun/moon theme toggle. Client state follows the OS until an explicit choice.
  """
  use Phoenix.Component
  use Gettext, backend: PortfolioWeb.Gettext

  attr :id, :string, default: "theme-switcher"
  attr :class, :string, default: nil

  @spec theme_switcher(map()) :: Phoenix.LiveView.Rendered.t()
  def theme_switcher(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      class={["theme-toggle noscript", @class]}
      phx-hook="ThemeSwitcher"
      phx-update="ignore"
      aria-label={gettext("Dark mode")}
      aria-pressed="false"
      title={gettext("Toggle light and dark mode")}
    >
      <svg
        width="28"
        height="28"
        viewBox="0 0 24 24"
        aria-hidden="true"
        focusable="false"
      >
        <defs>
          <mask
            id={"#{@id}-face"}
            maskUnits="userSpaceOnUse"
            x="0"
            y="0"
            width="24"
            height="24"
            style="mask-type: luminance"
          >
            <rect width="24" height="24" fill="white" />
            <g fill="black">
              <path data-part="eye" />
              <path data-part="mouth" />
              <g data-part="extra-eye"><path /></g>
              <g data-part="nose"><path /></g>
            </g>
          </mask>
        </defs>
        <path data-part="body" fill="currentColor" mask={"url(##{@id}-face)"} />
      </svg>
    </button>
    """
  end
end
