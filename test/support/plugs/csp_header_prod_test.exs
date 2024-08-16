# test/support/plugs/csp_header_prod_test.exs
defmodule PortfolioWeb.CSPHeaderProdTest do
  use PortfolioWeb.ConnCase
  alias PortfolioWeb.Plugs.CSPHeader

  describe "Production CSP Header" do
    test "script-src allows unsafe-inline in development" do
      config = %{
        scheme: "http",
        host: "localhost",
        port: "4000",
        additional_hosts: []
      }

      csp = CSPHeader.generate_csp_for_testing(config)
      assert csp =~ ~r/script-src[^;]*'unsafe-inline'/
    end

    test "style-src allows unsafe-inline in development" do
      config = %{
        scheme: "http",
        host: "localhost",
        port: "4000",
        additional_hosts: []
      }

      csp = CSPHeader.generate_csp_for_testing(config)
      assert csp =~ ~r/style-src[^;]*'unsafe-inline'/
    end

    test "frame-src is set to 'none' in production" do
      config = %{
        scheme: "https",
        host: "example.com",
        port: "443",
        additional_hosts: []
      }

      csp = CSPHeader.generate_csp_for_testing(config)
      assert csp =~ ~r/frame-src\s+'none'/
    end

    test "upgrade-insecure-requests is present in production" do
      config = %{
        scheme: "https",
        host: "example.com",
        port: "443",
        additional_hosts: []
      }

      csp = CSPHeader.generate_csp_for_testing(config)
      assert csp =~ "upgrade-insecure-requests"
    end
  end
end
