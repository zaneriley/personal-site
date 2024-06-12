require Logger

defmodule PortfolioWeb.UrlHelper do
  def sigil_i(path, _) do
    Logger.info("sigil_i called with #{inspect(path)}")
    locale = Gettext.get_locale(PortfolioWeb.Gettext)
    Logger.info("Locale: #{locale}, Path: #{path}")
    "#{path}"
  end
end
