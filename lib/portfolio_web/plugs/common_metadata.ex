defmodule PortfolioWeb.Plugs.CommonMetadata do
  import Plug.Conn

  alias PortfolioWeb.Plugs.SetLocale

  def init(opts), do: opts

  def call(conn, _opts) do
    {date, _time} = :calendar.local_time()
    {current_year, _month, _day} = date

    conn
    |> assign(:current_year, current_year)
    |> assign(:supported_locales, SetLocale.supported_locales())
  end
end
