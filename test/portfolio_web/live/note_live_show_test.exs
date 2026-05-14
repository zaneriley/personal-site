defmodule PortfolioWeb.NoteLive.ShowTest do
  use PortfolioWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Portfolio.ContentFixtures

  alias Portfolio.Content.TranslationRepository

  describe "GET /:locale/note/:url" do
    test "renders the note body with markdown compiled to HTML", %{conn: conn} do
      note =
        note_fixture(
          %{
            "url" => "render-smoke-note",
            "title" => "Render Smoke Note",
            "content" => "## A heading\n\nA paragraph with **bold** text."
          },
          skip_translations: true
        )

      {:ok, _view, html} = live(conn, ~p"/en/note/#{note.url}")

      assert html =~ "Render Smoke Note"
      assert html =~ "A heading"
      assert html =~ "A paragraph"
      assert html =~ "<strong>"
      assert html =~ ~s(href="/favicon-32x32.png")
      assert html =~ ~s(src="/js/app.js")
      refute html =~ "We ran into an issue loading this note"
      refute html =~ "## A heading"
      refute html =~ "preview.local"
    end

    test "renders translated body content when locale is set", %{conn: conn} do
      note =
        note_fixture(
          %{
            "url" => "translated-note",
            "content" => "English **content**."
          },
          skip_translations: true
        )

      {:ok, _} =
        TranslationRepository.create_or_update_translations(note, "ja", %{
          "title" => "日本語のタイトル",
          "introduction" => "日本語の紹介",
          "content" => "日本語の**コンテンツ**です。"
        })

      {:ok, _view, html} = live(conn, ~p"/ja/note/#{note.url}")

      assert html =~ "日本語のタイトル"
      assert html =~ "<strong>コンテンツ</strong>"
      refute html =~ "We ran into an issue loading this note"
      refute html =~ "<strong>content</strong>"
    end

    test "raises LiveError when the slug does not exist", %{conn: conn} do
      assert_raise PortfolioWeb.LiveError, fn ->
        live(conn, ~p"/en/note/this-slug-does-not-exist")
      end
    end
  end
end
