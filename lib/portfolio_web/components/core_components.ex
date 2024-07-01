defmodule PortfolioWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import PortfolioWeb.Gettext

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        Are you sure?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>

  JS commands may be passed to the `:on_cancel` and `on_confirm` attributes
  for the caller to react to each button press, for example:

      <.modal id="confirm" on_confirm={JS.push("delete")} on_cancel={JS.navigate(~p"/posts")}>
        Are you sure you?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}

  slot :inner_block, required: true
  slot :title
  slot :subtitle
  slot :confirm
  slot :cancel

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
    >
      <div id={"#{@id}-bg"} aria-hidden="true" />
      <div
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div>
          <div>
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && show_modal(@id)}
              phx-window-keydown={hide_modal(@on_cancel, @id)}
              phx-key="escape"
              phx-click-away={hide_modal(@on_cancel, @id)}
            >
              <div>
                <button
                  phx-click={hide_modal(@on_cancel, @id)}
                  type="button"
                  aria-label={gettext("close")}
                >
                  <Heroicons.x_mark solid class="h-6 w-6" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <header :if={@title != []}>
                  <h1 id={"#{@id}-title"}>
                    <%= render_slot(@title) %>
                  </h1>
                  <p :if={@subtitle != []} id={"#{@id}-description"}>
                    <%= render_slot(@subtitle) %>
                  </p>
                </header>
                <%= render_slot(@inner_block) %>
                <div :if={@confirm != [] or @cancel != []}>
                  <.button
                    :for={confirm <- @confirm}
                    id={"#{@id}-confirm"}
                    phx-click={@on_confirm}
                    phx-disable-with
                  >
                    <%= render_slot(confirm) %>
                  </.button>
                  <.link
                    :for={cancel <- @cancel}
                    phx-click={hide_modal(@on_cancel, @id)}
                  >
                    <%= render_slot(cancel) %>
                  </.link>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end


  @doc """
  Renders a logo.

  ## Examples

      <.logo class="w-16 h-16" />
  """
  def logo(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 122 150"
      width="122"
      height="150"
    >
      <path
        fill="currentColor"
        d="m3.17 56.5 33.6-46.66h-9.91c-6.06 0-9.06 3.38-11.9 10.78l-.46 1.32h-1.1L17.7 7.8h25.43l-.2.85L9.35 55.31H20.6c6.48 0 9.05-3.63 12.36-10.97l.6-1.32h1.1l-4.5 14.32H2.98l.2-.84Zm46.13-3.61c-.86 0-1.05-.66-1.05-1.59.13-1.58.49-3.14 1.05-4.62l5.44-16.44c-7.7 15.8-13.1 22.65-16.21 22.65-1.1 0-1.72-1-1.72-2.65 0-7.7 10.11-32.49 19.37-32.49 1.31.12 2.59.5 3.76 1.1l2.45-2.64 1.1.13L52.8 48.1a62.58 62.58 0 0 0 8.46-9.45l.8.66C56.7 46.9 51.48 52.89 49.3 52.89Zm-7.33-5c1.25 0 6.47-6.88 15.33-25.38l.2-.55c-1.1-1-2.32-1.85-3.64-1.85-5.68.02-12.33 22.56-12.33 27.05 0 .53.17.73.44.73Zm28.81-24.74c0-.46-.13-.73-.55-.73-1.19 0-2.71 1.85-5.22 6.55l-.86-.4c2.75-6.21 6.15-10.84 8.92-10.84 1.46 0 2.12.86 2.12 2.51 0 1.32-.4 3.04-1.2 5.29L69.5 38.75c6.94-15.2 12.5-21.02 16.2-21.02 1.58 0 2.3 1.1 2.3 3.04 0 1.32-.46 3.1-1.1 5.16l-7.92 22.16a68.01 68.01 0 0 0 7.93-9.45l.79.66c-5.16 7.46-10.05 13.59-12.1 13.59-.85 0-1.18-.73-1.18-1.72.12-1.61.5-3.2 1.1-4.7l7.31-20.06c.3-.87.5-1.79.55-2.71 0-.73-.2-1-.86-1-2.58 0-8.92 7.34-17.44 29.15H61.5l8.72-26.37c.3-.74.5-1.53.55-2.33Zm25.38 26.13c2.31 0 4.5-3.44 6.47-8.4l.93.47c-2.64 7.2-5.88 11.56-9.45 11.56-3.1 0-4.16-3.04-4.16-7.4 0-11.37 7.6-27.76 15.32-27.76 2.32 0 3.44 1.46 3.44 3.86 0 5.88-5.94 11.01-13.28 13.48a36.57 36.57 0 0 0-1.25 8.81c0 3.4.52 5.38 1.98 5.38Zm-.4-15.6c6.41-2.71 9.25-8.46 9.25-12.12 0-1.25-.4-1.91-1.19-1.91-2.57.02-6.08 6.76-8.06 14.03Z"
      />
      <g fill="currentColor" clip-path="url(#a)">
        <path d="M5.83 66.11c-.31.06-.61.1-.9.17l-.67.2a.17.17 0 0 1-.2-.06 3.94 3.94 0 0 1-.61-1.16 1.13 1.13 0 0 1-.03-.18c-.01-.1.04-.13.13-.11l.24.06c.36.08.73.11 1.1.1.31 0 .63-.04.95-.05V63.6a.25.25 0 0 0-.12-.23l-.43-.31c-.17-.12-.18-.2-.02-.34.13-.12.28-.22.42-.32a.3.3 0 0 1 .2-.04l1.37.4a.42.42 0 0 1 .32.4c0 .09-.01.19-.06.27a.98.98 0 0 0-.21.59l-.07.86v.06c.21-.03.42-.04.62-.08.43-.07.86-.14 1.29-.24.18-.05.35-.13.52-.23a.31.31 0 0 1 .3-.02l1.4.58a.59.59 0 0 1 .36.32.49.49 0 0 1-.24.65l-.79.41c-.4.24-.79.51-1.15.8-.4.3-.82.58-1.24.83-.26.15-.57.2-.86.15l-.06-.01c-.15-.06-.16-.12-.03-.22a9.24 9.24 0 0 0 1.73-2c.02-.07.01-.12-.07-.1l-.61.06-1.2.14-.06.01-.04.64c-.02.6-.04 1.2-.04 1.8a2.62 2.62 0 0 0 .08.63.5.5 0 0 0 .5.27c.32 0 .65-.02.97-.06.38-.05.76-.14 1.15-.19.36-.06.74.01 1.05.22.25.17.34.4.14.71a1.1 1.1 0 0 1-.78.48 7.86 7.86 0 0 1-2.7.05c-.3-.05-.6-.14-.88-.28a1.27 1.27 0 0 1-.69-1.02c-.05-.44-.09-.88-.1-1.32-.01-.55 0-1.11.01-1.66v-.15Zm3.04-3.56a2 2 0 0 1 1.2.36.77.77 0 0 1 .36.67.42.42 0 0 1-.26.39.41.41 0 0 1-.44-.12 1 1 0 0 1-.1-.12c-.25-.4-.62-.72-1.06-.9a1.02 1.02 0 0 1-.16-.08c-.03-.02-.06-.07-.06-.1a.13.13 0 0 1 .1-.06l.42-.04Zm1.33-.72c.49 0 .87.01 1.2.24a.56.56 0 0 1 .27.5.39.39 0 0 1-.26.36.44.44 0 0 1-.49-.11 2.2 2.2 0 0 0-1.29-.65c-.07-.01-.16 0-.16-.1s.09-.1.15-.12l.58-.12Z" />
      </g>
      <path
        fill="currentColor"
        d="M18.7 65.22c.1.1.18.2.26.3.12.16.18.36.17.55-.01.58-.03 1.15-.02 1.73 0 .44.04.87.05 1.32.02.42-.1.85-.35 1.2a.76.76 0 0 1-.56.37c-.1 0-.19 0-.28-.04a.83.83 0 0 1-.53-.94c.03-.31.1-.62.14-.94.1-.73.13-1.46.09-2.2l-.04-.55-.12.07c-.8.55-1.67 1-2.58 1.34-.45.18-.92.3-1.4.38a.9.9 0 0 1-.23 0c-.05 0-.09-.05-.13-.08.03-.04.05-.1.09-.11.31-.19.63-.36.94-.56.67-.43 1.3-.92 1.88-1.45a25.7 25.7 0 0 0 1.9-1.83l.9-1a.12.12 0 0 0 0-.2l-.2-.18c-.1-.09-.1-.16 0-.24l.42-.3c.1-.08.2-.03.28.02l.57.37c.18.12.36.26.54.4.07.06.13.13.18.2a.35.35 0 0 1-.12.55 1.7 1.7 0 0 0-.37.26l-1.48 1.56Z"
      />
      <g fill="currentColor" clip-path="url(#b)">
        <path d="M31.68 64.66a2.4 2.4 0 0 1-.12.38 7.62 7.62 0 0 1-1.9 2.28c-.68.53-1.42.96-2.21 1.27-.96.38-1.92.74-2.88 1.1a.46.46 0 0 1-.62-.21c-.25-.42-.4-.87-.47-1.35a.67.67 0 0 1 .07-.36c.08-.14.18-.26.3-.37.13-.12.25-.09.32.08.17.41.35.51.8.43a9 9 0 0 0 1.67-.53 16.92 16.92 0 0 0 3.6-1.83c.43-.3.84-.62 1.21-.99l.09-.08c.06-.05.1-.03.11.05v.12h.03Zm-4.46-.56c-.01.38-.2.56-.62.59l-.68.04c-.3.03-.57.15-.78.36a.6.6 0 0 1-.15.06.5.5 0 0 1 0-.16l.26-.66c.07-.16.06-.2-.11-.22a2.33 2.33 0 0 1-1.53-.95.93.93 0 0 1-.13-.26c-.04-.12.02-.2.14-.18.15.02.29.06.43.1.5.12 1.04.11 1.54-.03a.76.76 0 0 1 .78.2c.24.26.49.5.72.76a.43.43 0 0 1 .13.35Z" />
      </g>
      <g fill="currentColor" clip-path="url(#c)">
        <path d="M32.25 135.41h.33l-.2 1c-.98.17-1.98.26-2.97.26-3.3 0-3.97-.73-4.96-4.3L18.39 112h-3.37l-4.76 19.5c-.12.44-.19.91-.2 1.38 0 1.59 1 2.51 3.18 2.51h.86l-.27 1H-.37l.2-1H.6c2.76 0 4.37-1.52 4.96-3.9l9.63-39.76c.12-.45.19-.92.2-1.39 0-1.58-.93-2.51-3.11-2.51h-.86l.2-1h13.41c6.15 0 9.37 3.78 9.37 9.53 0 7.46-4.7 13.28-12.12 14.67l6.06 19.27c1.45 4.45 1.78 5.11 3.9 5.11ZM15.4 110.17h2.84c6.54 0 11.17-5.55 11.17-13.68 0-4.9-2.45-7.6-6.22-7.6h-2.64l-5.15 21.28Zm27.7-5.64a8.9 8.9 0 0 0 .56-2.31c0-.55-.13-.8-.55-.8-1.2 0-2.51 1.85-5.1 6.68l-.9-.47c2.85-6.2 6.15-10.83 9-10.83 1.38 0 1.98.99 1.98 2.5 0 1.4-.6 3.7-1.4 6.02L39.15 127a67.68 67.68 0 0 0 8.2-9.32l.79.66c-5.22 7.53-10.11 13.61-12.3 13.61-.85 0-1.18-.66-1.18-1.65 0-1.19.55-2.97 1.19-4.82l7.27-20.95Zm3.38-17.58a2.75 2.75 0 0 1 2.84-2.84 2.75 2.75 0 0 1 2.84 2.84 2.69 2.69 0 0 1-2.84 2.75 2.65 2.65 0 0 1-2.84-2.75Zm5.42 40.25a79.21 79.21 0 0 0 8.2-9.45l.7.59c-5.22 7.6-9.92 13.61-12.22 13.61-.86 0-1.2-.72-1.2-1.71.13-1.6.44-3.17.93-4.7l10.77-38h-3.43l.26-.86c3.23-1.25 6.1-3.56 8.67-6.67h.62L51.9 127.2Zm17.7 1.12c2.32 0 4.5-3.44 6.48-8.4l.93.47c-2.64 7.2-5.88 11.56-9.45 11.56-3.1 0-4.16-3.04-4.16-7.4 0-11.36 7.6-27.75 15.33-27.75 2.31 0 3.43 1.45 3.43 3.85 0 5.88-5.94 11.02-13.28 13.48a36.57 36.57 0 0 0-1.25 8.81c-.01 3.4.52 5.38 1.98 5.38Zm-.39-15.6c6.41-2.7 9.25-8.46 9.25-12.11 0-1.26-.4-1.92-1.19-1.92-2.58.04-6.08 6.76-8.06 14.03Zm20.95 22.21c.85-10.9.55-33.44-1.85-33.44-1 0-2.45 1.72-4.83 6.28l-.73-.55c2.45-5.55 5.42-10.47 7.87-10.47 3.96 0 4.4 20.82 3.3 31.72 4.36-8.13 7.8-17.31 7.8-22.93 0-3.3-.99-3.85-.99-6.21 0-1.59.8-2.58 2.2-2.58 1.59 0 2.2 1.46 2.2 3.7 0 11.17-16.58 47.98-28.02 47.98-1.91 0-2.9-.86-2.9-2.31a2.24 2.24 0 0 1 2.11-2.38c1.52 0 1.52 1.45 3.44 1.45 2.6.05 6.56-4.31 10.4-10.26ZM3.65 149c.03-.1.11-.1.18-.12l.43-.1a8.53 8.53 0 0 0 5.2-3.93c.04-.08.04-.08.03-.17l-.42.03-1.12.13-1.33.16-.9.14c-.24.03-.48.1-.7.19a.6.6 0 0 1-.54-.04l-.24-.16a2.68 2.68 0 0 1-.79-1.15c-.03-.12.02-.16.14-.12.58.21 1.19.2 1.8.2.44-.02.88-.04 1.32-.08l1.33-.11 1.2-.11c.32-.03.6-.09.85-.27.19-.14.37-.12.56-.02.3.16.58.36.83.6.1.09.16.2.16.34 0 .09-.03.16-.11.22-.29.19-.48.45-.64.73a7.57 7.57 0 0 1-3 2.96c-.5.25-1.05.41-1.62.52a15.2 15.2 0 0 1-2.5.2c-.04 0-.08-.02-.12-.04Zm2.05-6.1h-.71a.33.33 0 0 1-.29-.15c-.12-.2-.25-.38-.38-.57a.77.77 0 0 1-.09-.16c-.03-.08.02-.14.12-.12.55.12 1.1.06 1.65.03a15.6 15.6 0 0 0 2.16-.3c.2-.03.38-.08.55-.18a.43.43 0 0 1 .34-.04c.34.1.68.19.99.34.12.07.23.14.34.24.2.18.15.41-.08.56a.9.9 0 0 1-.43.14l-.76.05-2.52.11-.9.04Zm12.86 1.32c.1.1.18.2.26.3.12.16.18.35.17.55-.01.57-.03 1.15-.03 1.73 0 .43.05.87.06 1.31.02.43-.1.85-.35 1.2a.76.76 0 0 1-.56.37c-.1.01-.2 0-.28-.04a.82.82 0 0 1-.53-.93c.03-.31.1-.62.14-.94.1-.73.12-1.47.08-2.2l-.03-.55-.12.07c-.8.55-1.67 1-2.59 1.34-.44.17-.9.3-1.38.38a.87.87 0 0 1-.24 0c-.05 0-.1-.06-.14-.08.03-.04.06-.1.1-.12.3-.18.63-.35.94-.55a25.3 25.3 0 0 0 3.78-3.28l.9-1.01a.12.12 0 0 0 .03-.15.13.13 0 0 0-.04-.05l-.2-.17c-.09-.09-.09-.16 0-.24.14-.11.29-.21.43-.3.1-.08.2-.03.28.02l.56.36.55.4.18.21a.35.35 0 0 1 0 .45.36.36 0 0 1-.12.1 1.7 1.7 0 0 0-.38.26c-.5.51-.98 1.04-1.47 1.56Z" />
        <g clip-path="url(#d)">
          <path d="M23.7 149.34h-.28c-.04 0-.08 0-.1-.05 0-.05.03-.08.07-.1l.38-.12c.8-.27 1.45-.72 2-1.32.45-.5.8-1.03 1-1.65.14-.43.22-.88.27-1.33.07-.55.07-1.1.07-1.66 0-.26-.02-.5-.04-.76 0-.11-.05-.2-.16-.24l-.56-.26c-.2-.09-.21-.14-.06-.28.17-.16.36-.3.56-.42a.26.26 0 0 1 .12-.04c.04 0 .09 0 .12.02l1.08.43c.34.15.49.41.44.75-.12.87-.07 1.75-.11 2.62a5.87 5.87 0 0 1-.27 1.64 4.12 4.12 0 0 1-2.37 2.31 6.1 6.1 0 0 1-2.16.47Z" />
          <path d="M25.5 143.9c-.04.53-.07 1.14-.13 1.75a2.6 2.6 0 0 1-.13.67 1.28 1.28 0 0 1-.36.52c-.12.1-.19.1-.29-.02a1.76 1.76 0 0 1-.21-.26l-.38-.62a.72.72 0 0 1-.07-.5 13.66 13.66 0 0 0 .14-2.6c-.04-.26-.21-.44-.46-.56l-.18-.09c-.07-.04-.08-.1-.02-.15a.29.29 0 0 1 .08-.07l.5-.22c.23-.1.45-.07.66.03l.51.3c.19.11.3.28.3.5l.04 1.31Z" />
        </g>
        <path d="M39.48 145.42c0 .21-.13.36-.35.43a1.3 1.3 0 0 1-.57.02 11.2 11.2 0 0 0-1.64-.12H35.2a38.26 38.26 0 0 0-2.76.25.32.32 0 0 1-.33-.12c-.3-.37-.54-.77-.7-1.2-.01-.05-.06-.1 0-.16s.12-.01.19 0c.4.11.82.17 1.24.17a66.82 66.82 0 0 0 4.04-.08c.46-.03.9-.08 1.35-.15.48-.07.8.14 1.06.45.13.15.2.32.2.5Z" />
      </g>
      <defs>
        <clipPath id="a">
          <path
            fill="currentColor"
            d="M0 0h8.36v8.8H0z"
            transform="translate(3.42 61.83)"
          />
        </clipPath>
        <clipPath id="b">
          <path
            fill="currentColor"
            d="M0 0h8.22v7.03H0z"
            transform="translate(23.47 62.71)"
          />
        </clipPath>
        <clipPath id="c">
          <path
            fill="currentColor"
            d="M0 0h120.82v73.46H0z"
            transform="translate(.34 76.37)"
          />
        </clipPath>
        <clipPath id="d">
          <path
            fill="currentColor"
            d="M0 0h5.3v8.24H0z"
            transform="translate(23.32 141.11)"
          />
        </clipPath>
      </defs>
    </svg>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: nil, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil

  attr :kind, :atom,
    values: [:info, :error],
    doc: "used for styling and flash lookup"

  attr :autoshow, :boolean,
    default: true,
    doc: "whether to auto show the flash on mount"

  attr :close, :boolean, default: true, doc: "whether the flash can be closed"

  attr :rest, :global,
    doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block,
    doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-mounted={@autoshow && show("##{@id}")}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed hidden top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 shadow-md shadow-zinc-900/5 ring-1",
        @kind == :info &&
          "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error &&
          "bg-rose-50 p-3 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title}>
        <Heroicons.information_circle
          :if={@kind == :info}
          mini
          class="inline-block h-4 w-4"
        />
        <Heroicons.exclamation_circle
          :if={@kind == :error}
          mini
          class="inline-block h-4 w-4"
        />> <%= @title %>
      </p>
      <p><%= msg %></p>
      <button :if={@close} type="button" aria-label={gettext("close")}>
        <Heroicons.x_mark solid />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :id, :string,
    default: "flash-group",
    doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title="Success!" flash={@flash} />
      <.flash kind={:error} title="Error!" flash={@flash} />
      <.flash
        id="disconnected"
        kind={:error}
        title="We can't find the internet"
        close={false}
        autoshow={false}
        phx-disconnected={show("#disconnected")}
        phx-connected={hide("#disconnected")}
      >
        Attempting to reconnect <Heroicons.arrow_path class="inline-block h-4 w-4" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"

  attr :as, :any,
    default: nil,
    doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div>
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions}>
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values:
      ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc:
      "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"

  attr :options, :list,
    doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"

  attr :multiple, :boolean,
    default: false,
    doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include:
      ~w(autocomplete cols disabled form max maxlength min minlength
                                   pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn ->
      if assigns.multiple, do: field.name <> "[]", else: field.name
    end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label>
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id || @name}
          name={@name}
          value="true"
          checked={@checked}
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select id={@id} name={@name} multiple={@multiple} {@rest}>
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id || @name}
        name={@name}
        class={[
          "mt-2 block min-h-[6rem] w-full rounded-lg border-zinc-300 py-[7px] px-[11px]",
          "text-zinc-900 focus:border-zinc-400 focus:outline-none focus:ring-4 focus:ring-zinc-800/5 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5",
          "border-zinc-300 focus:border-zinc-400 focus:ring-zinc-800/5",
          @errors != [] &&
            "border-rose-400 focus:border-rose-400 focus:ring-rose-400/10"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg border-zinc-300 py-[7px] px-[11px]",
          "text-zinc-900 focus:outline-none focus:ring-4 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5",
          "border-zinc-300 focus:border-zinc-400 focus:ring-zinc-800/5",
          @errors != [] &&
            "border-rose-400 focus:border-rose-400 focus:ring-rose-400/10"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p>
      <Heroicons.exclamation_circle mini class="inline-block h-4 w-4" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[
      @actions != [] && "flex items-center justify-between gap-6",
      @class
    ]}>
      <div>
        <h1>
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []}>
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true

  attr :row_id, :any,
    default: nil,
    doc: "the function for generating the row id"

  attr :row_click, :any,
    default: nil,
    doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc:
      "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action,
    doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div>
      <table>
        <thead>
          <tr>
            <th :for={col <- @col}>
              <%= col[:label] %>
            </th>
            <th :if={@action != []}>
              <span><%= gettext("Actions") %></span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={[
                "relative p-0 align-top ",
                @row_click && "hover:cursor-pointer"
              ]}
            >
              <div>
                <span />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []}>
              <div>
                <span />
                <span :for={action <- @action}>
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div>
      <dl>
        <div :for={item <- @item}>
          <dt>
            <%= item.title %>
          </dt>
          <dd><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div>
      <.link navigate={@navigate}>
        <Heroicons.arrow_left solid class="inline-block h-4 w-4" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition:
        {"transition-all transform ease-out duration-300", "opacity-0",
         "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition:
        {"transition-all transform ease-in duration-200", "opacity-100",
         "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(PortfolioWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(PortfolioWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
