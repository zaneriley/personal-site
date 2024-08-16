# test/support/plugs/csp_header_dev_test.exs
defmodule PortfolioWeb.CSPHeaderDevTest do
  use PortfolioWeb.ConnCase
  alias PortfolioWeb.Plugs.CSPHeader
  alias PortfolioWeb.Plugs.CSPHeader.Dev

  describe "Development CSP Header" do
    test "frame-src is set to 'self' in development" do
      assert Dev.frame_src() == "'self'"
    end

    test "upgrade-insecure-requests is not added in development" do
      directives = [{"default-src", "'self'"}]
      assert Dev.maybe_add_upgrade_insecure_requests(directives) == directives
    end

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
  end
end
