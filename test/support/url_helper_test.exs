defmodule PortfolioWeb.UrlHelperTest do
  use PortfolioWeb.ConnCase, async: true

  alias PortfolioWeb.UrlHelper

  # Test generating URLs for different resource types with different locales
  test "generates URL for case study with locale" do
    conn = build_conn()
    locale = "en"
    case_study_slug = "example-case-study"
    assert UrlHelper.url(conn, locale, :case_study, case_study_slug) == "/en/case-study/example-case-study"
  end

  # test "generates URL for note with locale" do
  #   conn = build_conn()
  #   locale = "fr"
  #   note_slug = "example-note"
  #   assert UrlHelper.url(conn, locale, :note, note_slug) == "/fr/note/example-note"
  # end

  # Test generating URLs for the current page with different URL patterns and locales
  # test "generates URL for current case study page with locale" do
  #   conn = build_conn(:get, "/en/case-study/example-case-study")
  #   locale = "en"
  #   assert UrlHelper.current_page_url(conn, locale) == "/en/case-study/example-case-study"
  # end

  # test "generates URL for current note page with locale" do
  #   conn = build_conn(:get, "/fr/note/example-note")
  #   locale = "fr"
  #   assert UrlHelper.current_page_url(conn, locale) == "/fr/note/example-note"
  # end

  # Test fallback behavior when the locale is not provided or unsupported
  # test "falls back to root path when locale is not provided" do
  #   conn = build_conn()
  #   assert UrlHelper.url(conn, nil, :case_study, "example-case-study") == "/"
  # end

  # test "falls back to root path when locale is unsupported" do
  #   conn = build_conn()
  #   unsupported_locale = "de"
  #   assert UrlHelper.url(conn, unsupported_locale, :note, "example-note") == "/"
  # end
end
