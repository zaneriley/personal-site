defmodule PortfolioWeb.CSPHeaderTest do
  use PortfolioWeb.ConnCase
  import Plug.Conn

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
        assert csp =~ ~r/#{directive}\s/, "Missing critical directive: #{directive}"
      end
    end

    test "default-src is set to 'self'", %{csp: csp} do
      assert csp =~ ~r/default-src[^;]*'self'/
    end

    test "script-src does not allow unsafe-inline in production", %{csp: csp} do
      if Mix.env() == :prod do
        refute csp =~ ~r/script-src[^;]*'unsafe-inline'/
      end
    end

    test "object-src is set to 'none'", %{csp: csp} do
      assert csp =~ ~r/object-src\s+'none'/
    end

    test "frame-ancestors is set to 'none'", %{csp: csp} do
      assert csp =~ ~r/frame-ancestors\s+'none'/
    end
  end
end
