defmodule PortfolioWeb.CSPHeaderProdTest do
  use ExUnit.Case, async: true
  alias PortfolioWeb.Plugs.CSPHeader
  alias PortfolioWeb.Plugs.CSPHeader.Prod

  describe "frame_src/0" do
    test "is 'none' in production" do
      assert Prod.frame_src() == "'none'"
    end
  end

  describe "maybe_add_upgrade_insecure_requests/1" do
    test "prepends upgrade-insecure-requests" do
      directives = [{"default-src", "'self'"}]

      assert Prod.maybe_add_upgrade_insecure_requests(directives) ==
               [{"upgrade-insecure-requests", ""}, {"default-src", "'self'"}]
    end
  end

  describe "generate_csp_for_testing/3 with Prod env module" do
    test "frame-src is 'none' in the rendered policy" do
      csp =
        CSPHeader.generate_csp_for_testing(
          %{scheme: "https", host: "example.com", port: 443},
          [],
          Prod
        )

      assert csp =~ ~r/frame-src\s+'none'/
    end

    test "upgrade-insecure-requests is present" do
      csp =
        CSPHeader.generate_csp_for_testing(
          %{scheme: "https", host: "example.com", port: 443},
          [],
          Prod
        )

      assert csp =~ "upgrade-insecure-requests"
    end
  end
end
