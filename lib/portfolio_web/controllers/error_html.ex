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

  embed_templates "error_html/*"

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
