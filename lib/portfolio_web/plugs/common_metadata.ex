defmodule PortfolioWeb.Plugs.CommonMetadata do
  @moduledoc """
    A plug for injecting common metadata into the connection struct.

    This plug is responsible for adding metadata that is commonly used across different requests in the application. It performs the following actions:

      - Retrieves the current local date and extracts the year.
      - Assigns the current year to the `:current_year` key in the connection struct.

    By doing so, it makes the current year readily available to controllers and views, which can be useful for copyright notices, time-sensitive features, or any functionality that requires knowledge of the current year.

    After the plug is invoked, you can access the current year in your controllers and templates with `@conn.assigns.current_year`.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    {date, _time} = :calendar.local_time()
    {current_year, _month, _day} = date

    conn
    |> assign(:current_year, current_year)
  end
end
