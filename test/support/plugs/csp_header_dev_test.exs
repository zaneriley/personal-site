defmodule PortfolioWeb.CSPHeaderDevTest do
  use ExUnit.Case, async: true
  alias PortfolioWeb.Plugs.CSPHeader
  alias PortfolioWeb.Plugs.CSPHeader.Dev

  describe "frame_src/0" do
    test "is 'self' in development" do
      assert Dev.frame_src() == "'self'"
    end
  end

  describe "generate_csp_for_testing/3 with Dev env module" do
    test "frame-src is 'self' in the rendered policy" do
      csp =
        CSPHeader.generate_csp_for_testing(
          %{scheme: "http", host: "localhost", port: 4000},
          [],
          Dev
        )

      assert csp =~ ~r/frame-src\s+'self'/
    end

    test "script-src and style-src retain 'unsafe-inline' (pending hardening slice)" do
      csp =
        CSPHeader.generate_csp_for_testing(
          %{scheme: "http", host: "localhost", port: 4000},
          [],
          Dev
        )

      assert csp =~ ~r/script-src[^;]*'unsafe-inline'/
      assert csp =~ ~r/style-src[^;]*'unsafe-inline'/
    end
  end
end
