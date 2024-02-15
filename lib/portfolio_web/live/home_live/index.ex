defmodule PortfolioWeb.HomeLive do
  use Phoenix.LiveView
  use PortfolioWeb, :controller
  alias Portfolio.Content
  require Logger

  def mount(_params, %{"user_locale" => user_locale} = _session, socket) do
    case_studies = fetch_case_studies(user_locale)

    assigns = [
      :page_title,
      gettext(
        "Zane Riley: Expert Product Designer in Tokyo with 10+ Years of Experience"
      ),
      :page_description,
      gettext(
        "Zane Riley is a experienced Product Designer based in Tokyo, with 10+ years of experience in a variety of industries including healthcare, finance, and more. Product-focused, Zane brings a strong technical background to the table, building products that help people beyond the screen."
      ),
      :current_year,
      :case_studies,
      case_studies
    ]

    {:ok, socket |> assign(assigns)}
  end

  defp fetch_case_studies(user_locale) do
    page_number = 1

    case_studies =
      Portfolio.Content.get_all_case_studies(user_locale, page_number)

    {date, _time} = :calendar.local_time()
    {current_year, _month, _day} = date
    {case_studies, current_year}
  end
end
