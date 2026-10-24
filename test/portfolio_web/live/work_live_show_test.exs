defmodule PortfolioWeb.WorkLive.ShowTest do
  # Not async: setup clears the global content cache, which is shared state.
  use PortfolioWeb.ConnCase

  import Phoenix.LiveViewTest
  import Portfolio.ContentFixtures

  alias Portfolio.Content.TranslationRepository
  alias Portfolio.Repo

  describe "GET /:locale/work/:url" do
    setup do
      Portfolio.DataCase.clear_cache()

      project =
        project_fixture(%{
          "content" => "## Project heading\n\nA paragraph with **bold** text."
        })

      project = Repo.preload(project, :translations)
      %{project: project}
    end

    test "renders the project body with markdown compiled to HTML", %{
      conn: conn,
      project: project
    } do
      {:ok, view, html} = live(conn, ~p"/en/work/#{project.url}")

      assert html =~ "Project"
      assert html =~ project.title
      assert html =~ project.introduction
      assert html =~ "Project heading"
      assert html =~ "<strong>"

      assert page_title(view) =~
               "Product design case study: #{project.title} |"

      refute html =~ "We ran into an issue loading this project"
      refute html =~ "&lt;p&gt;"
      refute html =~ "## Project heading"
    end

    test "renders Japanese translation when locale is ja", %{conn: conn} do
      project = project_fixture()

      {:ok, _} =
        TranslationRepository.create_or_update_translations(project, "ja", %{
          "title" => "日本語のタイトル",
          "introduction" => "日本語の紹介"
        })

      _project = Repo.preload(project, :translations, force: true)

      {:ok, _view, html} = live(conn, ~p"/ja/work/#{project.url}")

      assert html =~ "日本語のタイトル"
      assert html =~ "日本語の紹介"
    end

    test "raises LiveError for a non-existent project", %{conn: conn} do
      assert_raise PortfolioWeb.LiveError, fn ->
        live(conn, ~p"/en/work/non-existent-url")
      end
    end

    test "raises LiveError for an invalid slug shape", %{conn: conn} do
      # `foo_bar` fails the slug regex (underscore not in `[a-z0-9-]`),
      # so the LV raises before any DB lookup runs.
      assert_raise PortfolioWeb.LiveError, fn ->
        live(conn, ~p"/en/work/foo_bar")
      end
    end

    test "emits Open Graph and Twitter Card meta tags", %{
      conn: conn,
      project: project
    } do
      {:ok, _view, html} = live(conn, ~p"/en/work/#{project.url}")

      assert html =~ ~r/<meta property="og:title" content="[^"]+"/
      assert html =~ ~s(<meta property="og:type" content="article")
      assert html =~ ~s(<meta property="og:url" content=")
      assert html =~ "/en/work/#{project.url}\""
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
