defmodule PortfolioWeb.SiteOriginTest do
  use ExUnit.Case, async: true

  alias PortfolioWeb.Endpoint
  alias PortfolioWeb.SiteOrigin

  describe "absolute_url/1" do
    test "prepends the configured endpoint origin to root-relative paths" do
      assert SiteOrigin.absolute_url("/en/note/hello") ==
               Endpoint.url() <> "/en/note/hello"
    end

    test "requires a root-relative path" do
      assert_raise FunctionClauseError, fn ->
        SiteOrigin.absolute_url("en/note/hello")
      end
    end
  end
end
