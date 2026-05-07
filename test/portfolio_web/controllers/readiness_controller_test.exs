defmodule PortfolioWeb.ReadinessControllerTest do
  @moduledoc false

  use PortfolioWeb.ConnCase, async: true

  describe "GET /readyz" do
    test "returns ok after the database responds", %{conn: conn} do
      conn = get(conn, ~p"/readyz")

      assert text_response(conn, 200) == "ok"
    end
  end
end
