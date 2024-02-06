defmodule PortfolioWeb.CaseStudyLiveTest do
  use PortfolioWeb.ConnCase

  import Phoenix.LiveViewTest
  import Portfolio.AdminFixtures

  @create_attrs %{title: "some title", url: "some url", role: "some role", timeline: "some timeline", read_time: 42, platforms: ["option1", "option2"], introduction: "some introduction", content: "some content"}
  @update_attrs %{title: "some updated title", url: "some updated url", role: "some updated role", timeline: "some updated timeline", read_time: 43, platforms: ["option1"], introduction: "some updated introduction", content: "some updated content"}
  @invalid_attrs %{title: nil, url: nil, role: nil, timeline: nil, read_time: nil, platforms: [], introduction: nil, content: nil}

  defp create_case_study(_) do
    case_study = case_study_fixture()
    %{case_study: case_study}
  end

  describe "Index" do
    setup [:create_case_study]

    test "lists all case_studies", %{conn: conn, case_study: case_study} do
      {:ok, _index_live, html} = live(conn, ~p"/case_studies")

      assert html =~ "Listing Case studies"
      assert html =~ case_study.title
    end

    test "saves new case_study", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/case_studies")

      assert index_live |> element("a", "New Case study") |> render_click() =~
               "New Case study"

      assert_patch(index_live, ~p"/case_studies/new")

      assert index_live
             |> form("#case_study-form", case_study: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#case_study-form", case_study: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/case_studies")

      html = render(index_live)
      assert html =~ "Case study created successfully"
      assert html =~ "some title"
    end

    test "updates case_study in listing", %{conn: conn, case_study: case_study} do
      {:ok, index_live, _html} = live(conn, ~p"/case_studies")

      assert index_live |> element("#case_studies-#{case_study.id} a", "Edit") |> render_click() =~
               "Edit Case study"

      assert_patch(index_live, ~p"/case_studies/#{case_study}/edit")

      assert index_live
             |> form("#case_study-form", case_study: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#case_study-form", case_study: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/case_studies")

      html = render(index_live)
      assert html =~ "Case study updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes case_study in listing", %{conn: conn, case_study: case_study} do
      {:ok, index_live, _html} = live(conn, ~p"/case_studies")

      assert index_live |> element("#case_studies-#{case_study.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#case_studies-#{case_study.id}")
    end
  end

  describe "Show" do
    setup [:create_case_study]

    test "displays case_study", %{conn: conn, case_study: case_study} do
      {:ok, _show_live, html} = live(conn, ~p"/case_studies/#{case_study}")

      assert html =~ "Show Case study"
      assert html =~ case_study.title
    end

    test "updates case_study within modal", %{conn: conn, case_study: case_study} do
      {:ok, show_live, _html} = live(conn, ~p"/case_studies/#{case_study}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Case study"

      assert_patch(show_live, ~p"/case_studies/#{case_study}/show/edit")

      assert show_live
             |> form("#case_study-form", case_study: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#case_study-form", case_study: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/case_studies/#{case_study}")

      html = render(show_live)
      assert html =~ "Case study updated successfully"
      assert html =~ "some updated title"
    end
  end
end
