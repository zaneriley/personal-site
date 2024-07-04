defmodule PortfolioWeb.ErrorHTML do
  @moduledoc """
  If you want to customize your error pages,
  uncomment the embed_templates/1 call below
  and add pages to the error directory:

    * lib/portfolio_web/controllers/error_html/404.html.heex
    * lib/portfolio_web/controllers/error_html/500.html.heex



  The default is to render a plain text page based on
  the template name. For example, "404.html" becomes
  "Not Found".
  """
  use PortfolioWeb, :html
  import PortfolioWeb.Gettext

  embed_templates "error_html/*"

  def dynamic_home_url do
    scheme = Application.get_env(:portfolio, :url_scheme, "http")
    host = Application.get_env(:portfolio, :url_host, "localhost")
    port = Application.get_env(:portfolio, :url_port, "8000")

    port_segment = if port in ["80", "443"], do: "", else: ":#{port}"
    "#{scheme}://#{host}#{port_segment}"
  end

  def render(embed_template, _assigns) do
    Phoenix.Controller.status_message_from_template(embed_template)
  end
end
