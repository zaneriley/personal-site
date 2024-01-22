defmodule PortfolioWeb.Plugs.SetLocale do
  import Plug.Conn
  import PortfolioWeb.Gettext

  def init(default), do: default

  def call(%{params: %{"locale" => loc}} = conn, _default) do
    case loc do
      "en" -> Gettext.put_locale(PortfolioWeb.Gettext, "en")
      "jp" -> Gettext.put_locale(PortfolioWeb.Gettext, "jp")
      _    -> Gettext.put_locale(PortfolioWeb.Gettext, "en") # default or 404
    end
    conn
  end
end
