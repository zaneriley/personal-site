defmodule PortfolioWeb.SessionControllerTest do
  use PortfolioWeb.ConnCase, async: true

  describe "generate/2" do
    test "generates a token and user_id", %{conn: conn} do
      conn = post conn, "/api/session/generate"
      assert json_response(conn, 200)
      response = json_response(conn, 200)
      assert is_map(response)
      assert Map.has_key?(response, "token")
      assert Map.has_key?(response, "user_id")
      assert is_binary(response["token"])
      assert is_integer(response["user_id"])
    end
  end

end
