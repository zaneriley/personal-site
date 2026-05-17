defmodule PortfolioWeb.ErrorHTMLTest do
  use PortfolioWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    html = render_to_string(PortfolioWeb.ErrorHTML, "404", "html", [])

    assert html =~ "ERROR 404"
    assert html =~ "DATA NOT FOUND"
    refute html =~ "localhost"
  end

  test "renders 500.html" do
    html = render_to_string(PortfolioWeb.ErrorHTML, "500", "html", [])

    assert html =~ "ERROR 500"
    assert html =~ "INTERNAL SERVER ERROR"
    refute html =~ "localhost"
  end
end
