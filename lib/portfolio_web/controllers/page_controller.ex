defmodule PortfolioWeb.PageController do
  use PortfolioWeb, :controller
  require Logger
  alias Portfolio.Content

  def home(conn, params) do
    Logger.debug(
      "Rendering home for locale: #{Gettext.get_locale(PortfolioWeb.Gettext)}"
    )

    run_mode = if System.get_env("RELEASE_NAME"), do: "release", else: "mix"

    # Fetch page number from query params or default to 1
    page_number = params["page"] || 1

    case_studies =
      Content.get_all_case_studies(conn.assigns.user_locale, page_number)

    {date, _time} = :calendar.local_time()
    {current_year, _month, _day} = date
    # Logger.debug("Case Studies: #{inspect(case_studies)}")

    conn
    |> assign(
      :page_title,
      gettext(
        "Zane Riley: Expert Product Designer in Tokyo with 10+ Years of Experience"
      )
    )
    |> assign(
      :page_description,
      gettext(
        "Zane Riley is a experienced Product Designer based in Tokyo, with 10+ years of experience in a variety of industries including healthcare, finance, and more. Product-focused, Zane brings a strong technical background to the table, building products that help people beyond the screen."
      )
    )
    |> assign(:current_year, current_year)
    # |> assign(:case_studies, case_studies)
    |> render(:home,
      run_mode: run_mode,
      phoenix_ver: Application.spec(:phoenix, :vsn),
      elixir_ver: System.version()
    )
  end
end
