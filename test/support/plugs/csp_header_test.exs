defmodule PortfolioWeb.CSPHeaderTest do
  use PortfolioWeb.ConnCase
  import Plug.Conn
  require Logger
  alias PortfolioWeb.Plugs.CSPHeader

  describe "CSP Header Tests" do
    setup %{conn: conn} do
      conn = get(conn, "/")
      [csp] = get_resp_header(conn, "content-security-policy")
      %{conn: conn, csp: csp}
    end

    test "CSP header is present", %{csp: csp} do
      assert csp != nil and csp != ""
    end

    test "CSP header contains critical directives", %{csp: csp} do
      critical_directives = ~w(default-src script-src style-src connect-src)

      for directive <- critical_directives do
        assert csp =~ ~r/#{directive}\s/,
               "Missing critical directive: #{directive}"
      end
    end

    test "default-src is set to 'self'", %{csp: csp} do
      assert csp =~ ~r/default-src[^;]*'self'/
    end

    test "object-src is set to 'none'", %{csp: csp} do
      assert csp =~ ~r/object-src\s+'none'/
    end

    test "frame-ancestors is set to 'none'", %{csp: csp} do
      assert csp =~ ~r/frame-ancestors\s+'none'/
    end

    test "CSP header is generated correctly for different configurations" do
      configs = [
        %{
          scheme: "http",
          host: "localhost",
          port: "4000",
          additional_hosts: []
        },
        %{
          scheme: "https",
          host: "example.com",
          port: "443",
          additional_hosts: ["api.example.com"]
        }
      ]

      for config <- configs do
        csp = CSPHeader.generate_csp_for_testing(config)
        assert csp =~ ~r/default-src\s+'self'/
        assert csp =~ ~r/connect-src\s+'self'/
        assert csp =~ config.host

        if config.additional_hosts != [],
          do: assert(csp =~ hd(config.additional_hosts))
      end
    end
  end
end
