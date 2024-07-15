defmodule PortfolioWeb.CaseStudyLive.ShowTest do
  use PortfolioWeb.ConnCase
  import Phoenix.LiveViewTest
  alias PortfolioWeb.Router.Helpers, as: Routes
  import Portfolio.AdminFixtures
  alias Portfolio.Repo

  describe "Case Study Show" do
    setup do
      case_study = case_study_fixture(%{include_translations: true})
      # Explicitly preload translations
      case_study = Repo.preload(case_study, :translations)
      %{case_study: case_study}
    end

    test "loads and displays a case study", %{conn: conn, case_study: case_study} do
      user_locale = "en"

      {:ok, _show_live, html} =
        live(conn, Routes.case_study_show_path(conn, :show, user_locale, case_study.url))

      assert html =~ "Case Study"
      assert html =~ case_study.title
      assert html =~ case_study.introduction
    end

    test "displays Japanese translation when locale is set to ja", %{conn: conn, case_study: case_study} do
      user_locale = "ja"

      {:ok, _show_live, html} =
        live(conn, Routes.case_study_show_path(conn, :show, user_locale, case_study.url))

      ja_title = Enum.find(case_study.translations, &(&1.field_name == "title" and &1.locale == "ja"))
      ja_introduction = Enum.find(case_study.translations, &(&1.field_name == "introduction" and &1.locale == "ja"))

      assert ja_title, "Japanese title translation not found"
      assert ja_introduction, "Japanese introduction translation not found"
      assert html =~ ja_title.field_value
      assert html =~ ja_introduction.field_value
    end

    test "handles non-existent case study gracefully", %{conn: conn} do
      user_locale = "en"
      non_existent_url = "non-existent-url"

      assert_error_sent 404, fn ->
        get(conn, Routes.case_study_show_path(conn, :show, user_locale, non_existent_url))
      end
    end
  end

end
