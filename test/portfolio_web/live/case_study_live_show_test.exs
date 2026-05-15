defmodule PortfolioWeb.CaseStudyLive.ShowTest do
  # Not async: setup clears the global content cache, which is shared state.
  use PortfolioWeb.ConnCase

  import Phoenix.LiveViewTest
  import Portfolio.ContentFixtures

  alias Portfolio.Content.TranslationRepository
  alias Portfolio.Repo

  describe "GET /:locale/case-study/:url" do
    setup do
      Portfolio.DataCase.clear_cache()

      case_study =
        case_study_fixture(%{
          "content" =>
            "## Case study heading\n\nA paragraph with **bold** text."
        })

      case_study = Repo.preload(case_study, :translations)
      %{case_study: case_study}
    end

    test "renders the case study body with markdown compiled to HTML", %{
      conn: conn,
      case_study: case_study
    } do
      {:ok, _view, html} = live(conn, ~p"/en/case-study/#{case_study.url}")

      assert html =~ "Case Study"
      assert html =~ case_study.title
      assert html =~ case_study.introduction
      assert html =~ "Case study heading"
      assert html =~ "<strong>"
      refute html =~ "We ran into an issue loading this case study"
      refute html =~ "&lt;p&gt;"
      refute html =~ "## Case study heading"
    end

    test "renders Japanese translation when locale is ja", %{conn: conn} do
      case_study = case_study_fixture()

      {:ok, _} =
        TranslationRepository.create_or_update_translations(case_study, "ja", %{
          "title" => "日本語のタイトル",
          "introduction" => "日本語の紹介"
        })

      _case_study = Repo.preload(case_study, :translations, force: true)

      {:ok, _view, html} = live(conn, ~p"/ja/case-study/#{case_study.url}")

      assert html =~ "日本語のタイトル"
      assert html =~ "日本語の紹介"
    end

    test "raises LiveError for a non-existent case study", %{conn: conn} do
      assert_raise PortfolioWeb.LiveError, fn ->
        live(conn, ~p"/en/case-study/non-existent-url")
      end
    end

    test "raises LiveError for an invalid slug shape", %{conn: conn} do
      # `foo_bar` fails the slug regex (underscore not in `[a-z0-9-]`),
      # so the LV raises before any DB lookup runs.
      assert_raise PortfolioWeb.LiveError, fn ->
        live(conn, ~p"/en/case-study/foo_bar")
      end
    end

    test "emits Open Graph and Twitter Card meta tags", %{
      conn: conn,
      case_study: case_study
    } do
      {:ok, _view, html} = live(conn, ~p"/en/case-study/#{case_study.url}")

      assert html =~ ~r/<meta property="og:title" content="[^"]+"/
      assert html =~ ~s(<meta property="og:type" content="article")
      assert html =~ ~s(<meta property="og:url" content=")
      assert html =~ "/en/case-study/#{case_study.url}\""
      assert html =~ ~s(/images/og-default.png)
      assert html =~ ~s(<meta property="og:locale" content="en")
      assert html =~ ~s(<meta property="og:locale:alternate" content="ja")
      assert html =~ ~s(<meta name="twitter:card" content="summary_large_image")
      assert html =~ ~s(<meta name="twitter:site" content="@zaneriley")
      refute html =~ "og_meta"
      refute html =~ "preview.local"
    end
  end
end
