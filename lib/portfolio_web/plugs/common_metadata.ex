defmodule PortfolioWeb.Plugs.CommonMetadata do
  @moduledoc """
  Assigns the metadata that the root layout requires for every browser request.

  LiveView pages override `:user_locale`, `:current_path`, `:page_title`,
  `:page_description`, and `:share_metadata` via `LiveHelpers.setup_common_assigns/3`.
  Controller-rendered pages take the defaults from this plug. The layout uses
  assertive access on `:share_metadata` and `:current_path`, so both must be
  present on every browser-pipelined response.
  """
  @behaviour Plug

  import Plug.Conn
  alias PortfolioWeb.ShareMetadata

  @default_title "Zane Riley | Product Designer"
  @default_description "Portfolio of Zane Riley, a Product Designer based in Tokyo with over 10 years of experience."

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    {date, _time} = :calendar.local_time()
    {current_year, _month, _day} = date

    user_locale =
      get_session(conn, "user_locale") ||
        Application.get_env(:portfolio, :default_locale)

    current_path = conn.request_path

    share_metadata =
      ShareMetadata.build(
        title: @default_title,
        description: @default_description,
        locale: user_locale,
        path: current_path
      )

    conn
    |> assign(:current_year, current_year)
    |> assign(:user_locale, user_locale)
    |> assign(:current_path, current_path)
    |> assign(:page_title, @default_title)
    |> assign(:page_description, @default_description)
    |> assign(:share_metadata, share_metadata)
  end
end
