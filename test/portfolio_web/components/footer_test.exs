defmodule PortfolioWeb.Components.FooterTest do
  use PortfolioWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias PortfolioWeb.Components.Footer

  @now ~U[2026-11-04 12:00:00Z]

  describe "last_change_label/2" do
    test "counts whole days, then months" do
      assert Footer.last_change_label(nil, @now) == nil
      assert Footer.last_change_label(~U[2026-11-04 00:10:00Z], @now) == "today"

      assert Footer.last_change_label(~U[2026-11-03 23:59:00Z], @now) ==
               "yesterday"

      assert Footer.last_change_label(~U[2026-11-02 12:00:00Z], @now) ==
               "2 days ago"

      assert Footer.last_change_label(~U[2026-09-06 12:00:00Z], @now) ==
               "59 days ago"

      assert Footer.last_change_label(~U[2026-09-05 12:00:00Z], @now) ==
               "2 months ago"
    end
  end

  describe "site_footer/1" do
    @status %{
      node_name: "Raspberry Pi 3B",
      node_up: true,
      version: "5",
      stack: "Elixir · Phoenix",
      changes: 503,
      last_change_at: DateTime.utc_now()
    }

    test "shows the version, change count, last change and stack" do
      html =
        render_component(&Footer.site_footer/1,
          current_year: 2026,
          status: @status
        )

      for text <- [
            "Version",
            "Changes",
            "503",
            "Last change",
            "today",
            "Built with"
          ] do
        assert html =~ text
      end

      assert html =~ "Elixir · Phoenix"
      assert html =~ "© 2010 – 2026"
      refute html =~ "Temp"
      refute html =~ "Cost"
    end

    test "leaves out history rows it has no source for" do
      status = %{@status | changes: nil, last_change_at: nil}

      html =
        render_component(&Footer.site_footer/1,
          current_year: 2026,
          status: status
        )

      assert html =~ "Version"
      refute html =~ "Changes"
      refute html =~ "Last change"
    end
  end
end
