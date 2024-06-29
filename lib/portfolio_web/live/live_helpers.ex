defmodule PortfolioWeb.LiveHelpers do
  import Phoenix.Component
  import PortfolioWeb.Gettext

  @default_title gettext("Zane Riley | Product Designer")
  @default_description gettext(
                         "Portfolio of Zane Riley, a Product Designer based in Tokyo with over 10 years of experience."
                       )

  def on_mount(:default, params, session, socket) do
    socket = setup_common_assigns(socket, params, session)
    {:cont, socket}
  end

  def on_mount(:admin, params, session, socket) do
    socket = setup_common_assigns(socket, params, session)
    {:cont, assign(socket, :admin, true)}
  end

  defp setup_common_assigns(socket, params, session) do
    user_locale = get_user_locale(session)
    Gettext.put_locale(PortfolioWeb.Gettext, user_locale)

    {date, _time} = :calendar.local_time()
    {current_year, _month, _day} = date

    socket
    |> assign(:current_year, current_year)
    |> assign(:user_locale, user_locale)
    |> assign(
      :current_path,
      params["request_path"] || socket.assigns[:current_path] || "/"
    )
    |> assign_default_page_metadata()
  end

  def assign_page_metadata(socket, title \\ nil, description \\ nil) do
    assign(socket,
      page_title: title || socket.assigns[:page_title] || @default_title,
      page_description:
        description || socket.assigns[:page_description] || @default_description
    )
  end

  defp assign_default_page_metadata(socket) do
    {date, _time} = :calendar.local_time()
    {current_year, _month, _day} = date
    assign(socket,
      page_title: @default_title,
      page_description: @default_description
    )
  end

  defp get_user_locale(session) do
    session["user_locale"] || Application.get_env(:portfolio, :default_locale)
  end

  def handle_locale_and_path(socket, params, uri) do
    new_locale = params["locale"] || socket.assigns.user_locale
    current_path = URI.parse(uri).path

    socket = assign(socket, current_path: current_path)

    if new_locale != socket.assigns.user_locale do
      Gettext.put_locale(PortfolioWeb.Gettext, new_locale)
      assign(socket, user_locale: new_locale)
    else
      socket
    end
  end

  def assign_locale(socket, session) do
    user_locale = get_user_locale(session)
    Gettext.put_locale(PortfolioWeb.Gettext, user_locale)
    assign(socket, user_locale: user_locale)
  end
end
