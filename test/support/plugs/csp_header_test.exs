defmodule PortfolioWeb.CSPHeaderTest do
  use ExUnit.Case, async: false
  import Plug.Test
  alias PortfolioWeb.Plugs.CSPHeader

  @moduletag :csp_header

  setup do
    previous_additional = System.get_env("CSP_ADDITIONAL_HOSTS")
    previous_csp_app = Application.get_env(:portfolio, :csp, [])
    System.delete_env("CSP_ADDITIONAL_HOSTS")

    Application.put_env(
      :portfolio,
      :csp,
      Keyword.put(previous_csp_app, :report_only, false)
    )

    on_exit(fn ->
      if previous_additional do
        System.put_env("CSP_ADDITIONAL_HOSTS", previous_additional)
      else
        System.delete_env("CSP_ADDITIONAL_HOSTS")
      end

      Application.put_env(:portfolio, :csp, previous_csp_app)
    end)

    :ok
  end

  describe "call/2" do
    test "derives default-src origin from conn (https + non-standard port)" do
      conn = build_conn(:https, "preview-1-2-3-4.example", 8443)
      conn = CSPHeader.call(conn, [])
      [csp] = Plug.Conn.get_resp_header(conn, "content-security-policy")

      assert csp =~ "default-src 'self' https://preview-1-2-3-4.example:8443"
    end

    test "derives connect-src with wss when conn is https" do
      conn = build_conn(:https, "preview-1-2-3-4.example", 8443)
      conn = CSPHeader.call(conn, [])
      [csp] = Plug.Conn.get_resp_header(conn, "content-security-policy")

      assert csp =~ "wss://preview-1-2-3-4.example:8443"
      refute csp =~ "ws://preview-1-2-3-4.example"
    end

    test "derives connect-src with ws when conn is http" do
      conn = build_conn(:http, "147.182.0.1", 8000)
      conn = CSPHeader.call(conn, [])
      [csp] = Plug.Conn.get_resp_header(conn, "content-security-policy")

      assert csp =~ "ws://147.182.0.1:8000"
      refute csp =~ ~r/wss:\/\/147\.182\.0\.1/
    end

    test "elides :80 from origin tokens" do
      conn = build_conn(:http, "example.com", 80)
      conn = CSPHeader.call(conn, [])
      [csp] = Plug.Conn.get_resp_header(conn, "content-security-policy")

      assert csp =~ "http://example.com"
      refute csp =~ ":80"
    end

    test "elides :443 from origin tokens" do
      conn = build_conn(:https, "zaneriley.com", 443)
      conn = CSPHeader.call(conn, [])
      [csp] = Plug.Conn.get_resp_header(conn, "content-security-policy")

      assert csp =~ "https://zaneriley.com"
      refute csp =~ ":443"
    end

    test "emits no extra hosts when CSP_ADDITIONAL_HOSTS is empty" do
      conn = build_conn(:https, "zaneriley.com", 443)
      conn = CSPHeader.call(conn, [])
      [csp] = Plug.Conn.get_resp_header(conn, "content-security-policy")

      refute csp =~ "localhost"
      refute csp =~ "0.0.0.0"
      refute csp =~ "plausible.io"
    end

    test "includes CSP_ADDITIONAL_HOSTS when set" do
      System.put_env("CSP_ADDITIONAL_HOSTS", "plausible.io,cdn.example.com")
      conn = build_conn(:https, "zaneriley.com", 443)
      conn = CSPHeader.call(conn, [])
      [csp] = Plug.Conn.get_resp_header(conn, "content-security-policy")

      assert csp =~ "https://plausible.io"
      assert csp =~ "https://cdn.example.com"
    end

    test "uses report-only header when configured" do
      Application.put_env(:portfolio, :csp, report_only: true)
      conn = build_conn(:https, "zaneriley.com", 443)
      conn = CSPHeader.call(conn, [])

      assert Plug.Conn.get_resp_header(conn, "content-security-policy") == []

      [_csp] =
        Plug.Conn.get_resp_header(conn, "content-security-policy-report-only")
    end

    test "includes critical directives" do
      conn = build_conn(:https, "zaneriley.com", 443)
      conn = CSPHeader.call(conn, [])
      [csp] = Plug.Conn.get_resp_header(conn, "content-security-policy")

      for directive <-
            ~w(default-src script-src style-src img-src font-src connect-src
                          frame-src object-src base-uri form-action frame-ancestors) do
        assert csp =~ ~r/#{directive}\s/, "Missing directive: #{directive}"
      end
    end

    test "object-src is 'none' and frame-ancestors is 'none'" do
      conn = build_conn(:https, "zaneriley.com", 443)
      conn = CSPHeader.call(conn, [])
      [csp] = Plug.Conn.get_resp_header(conn, "content-security-policy")

      assert csp =~ ~r/object-src\s+'none'/
      assert csp =~ ~r/frame-ancestors\s+'none'/
    end
  end

  describe "generate_csp_for_testing/3" do
    test "builds a string with request-origin self plus extras (prod env)" do
      csp =
        CSPHeader.generate_csp_for_testing(
          %{scheme: "https", host: "example.com", port: 443},
          ["analytics.example"],
          PortfolioWeb.Plugs.CSPHeader.Prod
        )

      assert csp =~ ~r/default-src\s+'self'/
      assert csp =~ "https://example.com"
      assert csp =~ "https://analytics.example"
      assert csp =~ "upgrade-insecure-requests"
    end

    test "dev env module omits upgrade-insecure-requests and sets frame-src 'self'" do
      csp =
        CSPHeader.generate_csp_for_testing(
          %{scheme: "http", host: "localhost", port: 4000},
          [],
          PortfolioWeb.Plugs.CSPHeader.Dev
        )

      refute csp =~ "upgrade-insecure-requests"
      assert csp =~ ~r/frame-src\s+'self'/
    end
  end

  defp build_conn(scheme, host, port) do
    %{conn(:get, "/") | scheme: scheme, host: host, port: port}
  end
end
