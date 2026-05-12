defmodule PortfolioWeb.Plugs.ContentAliasRedirectTest do
  use PortfolioWeb.ConnCase

  import Portfolio.ContentFixtures

  describe "content alias redirects" do
    test "redirects a note alias to the canonical note URL", %{conn: conn} do
      note =
        note_fixture(
          %{
            "url" => "renamed-note",
            "aliases" => ["old-note"]
          },
          skip_translations: true
        )

      conn = get(conn, ~p"/en/note/old-note")

      assert redirected_to(conn, 301) == ~p"/en/note/#{note.url}"
    end

    test "redirects a case study alias to the canonical case study URL", %{
      conn: conn
    } do
      case_study =
        case_study_fixture(%{
          "url" => "renamed-case-study",
          "aliases" => ["old-case-study"]
        })

      conn = get(conn, ~p"/en/case-study/old-case-study")

      assert redirected_to(conn, 301) ==
               ~p"/en/case-study/#{case_study.url}"
    end

    test "leaves a pure deleted note URL as the existing 404 behavior", %{
      conn: conn
    } do
      assert_error_sent 404, fn ->
        get(conn, ~p"/en/note/deleted-note-without-alias")
      end
    end
  end
end
