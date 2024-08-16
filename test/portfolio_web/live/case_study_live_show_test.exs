defmodule PortfolioWeb.CaseStudyLive.ShowTest do
  use PortfolioWeb.ConnCase
  import Phoenix.LiveViewTest
  alias PortfolioWeb.Router.Helpers, as: Routes
  import Portfolio.ContentFixtures
  alias Portfolio.Repo
  require Logger

  describe "Case Study Show" do
    setup do
      Portfolio.DataCase.clear_cache()
      case_study = case_study_fixture(%{include_translations: true})

      # Explicitly preload translations
      case_study = Repo.preload(case_study, :translations)
      %{case_study: case_study}
    end

    test "loads and displays a case study", %{
      conn: conn,
      case_study: case_study
    } do
      user_locale = "en"

      {:ok, _show_live, html} =
        live(
          conn,
          Routes.case_study_show_path(conn, :show, user_locale, case_study.url)
        )

      assert html =~ "Case Study"
      assert html =~ case_study.title
      assert html =~ case_study.introduction
    end

    test "displays Japanese translation when locale is set to ja", %{conn: conn} do
      user_locale = "ja"
      case_study = case_study_fixture()

      # Add specific Japanese translations
      Portfolio.Content.TranslationManager.create_or_update_translations(
        case_study,
        "ja",
        %{
          "title" => "日本語のタイトル",
          "introduction" => "日本語の紹介"
        }
      )

      # Reload the case study to include the new translations
      case_study =
        Portfolio.Repo.preload(case_study, :translations, force: true)

      Logger.debug("Case study: #{inspect(case_study)}")
      Logger.debug("Translations: #{inspect(case_study.translations)}")

      {:ok, show_live, html} =
        live(
          conn,
          Routes.case_study_show_path(conn, :show, user_locale, case_study.url)
        )

      assert html =~ "日本語のタイトル"
      assert html =~ "日本語の紹介"
    end

    test "handles non-existent case study gracefully", %{conn: conn} do
      user_locale = "en"
      non_existent_url = "non-existent-url"

      assert_error_sent 404, fn ->
        get(
          conn,
          Routes.case_study_show_path(
            conn,
            :show,
            user_locale,
            non_existent_url
          )
        )
      end
    end
  end
end
