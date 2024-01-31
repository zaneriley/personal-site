defmodule PortfolioWeb.PageController do
  use PortfolioWeb, :controller
  require Logger

  alias PortfolioWeb.Plugs.SetLocale
  alias Portfolio.Content
  alias PortfolioWeb.UrlHelper


  def home(conn, _params) do
    Logger.debug("Rendering home for locale: #{Gettext.get_locale(PortfolioWeb.Gettext)}")

    run_mode = if System.get_env("RELEASE_NAME"), do: "release", else: "mix"

    user_locale = conn.assigns.user_locale || "en"  # Fetch the current locale
    supported_locales = SetLocale.supported_locales()

    page_number = _params["page"] || 1  # Fetch page number from query params or default to 1
    case_studies = Content.get_all_case_studies(user_locale, page_number)  # Fetch paginated case studies for the current locale

    {date, _time} = :calendar.local_time()
    {current_year, _month, _day} = date
    Logger.debug("Case Studies: #{inspect(case_studies)}")

    conn
    |> assign(:page_title, gettext("Zane Riley: Expert Product Designer in Tokyo with 10+ Years of Experience"))
    |> assign(:page_description, gettext("Zane Riley is a experienced Product Designer based in Tokyo, with 10+ years of experience in a variety of industries including healthcare, finance, and more. Product-focused, Zane brings a strong technical background to the table, building products that help people beyond the screen."))
    |> assign(:current_year, current_year)
    |> assign(:case_studies, case_studies)
    |> assign(:user_locale, user_locale)  # Make sure to assign user_locale so it's available in the template
    |> assign(:supported_locales, supported_locales)
    |> render(:home,
      run_mode: run_mode,
      phoenix_ver: Application.spec(:phoenix, :vsn),
      elixir_ver: System.version()
    )
  end

  def root(conn, _params) do
    user_locale = get_session(conn, "user_locale") || "en"
    redirect_locale = case user_locale do
      "ja" -> "jp"
      locale -> locale
    end
    conn
    |> redirect(to: "/#{redirect_locale}/")
    |> halt()
  end
end
