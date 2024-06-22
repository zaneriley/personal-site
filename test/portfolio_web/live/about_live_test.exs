defmodule PortfolioWeb.AboutLiveTest do
  use PortfolioWeb.ConnCase

  import Phoenix.LiveViewTest
  import Portfolio.PageFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_about(_) do
    about = about_fixture()
    %{about: about}
  end

  describe "Index" do
    setup [:create_about]

    test "lists all about", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/about")

      assert html =~ "Listing About"
    end

    test "saves new about", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/about")

      assert index_live |> element("a", "New About") |> render_click() =~
               "New About"

      assert_patch(index_live, ~p"/about/new")

      assert index_live
             |> form("#about-form", about: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#about-form", about: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/about")

      html = render(index_live)
      assert html =~ "About created successfully"
    end

    test "updates about in listing", %{conn: conn, about: about} do
      {:ok, index_live, _html} = live(conn, ~p"/about")

      assert index_live |> element("#about-#{about.id} a", "Edit") |> render_click() =~
               "Edit About"

      assert_patch(index_live, ~p"/about/#{about}/edit")

      assert index_live
             |> form("#about-form", about: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#about-form", about: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/about")

      html = render(index_live)
      assert html =~ "About updated successfully"
    end

    test "deletes about in listing", %{conn: conn, about: about} do
      {:ok, index_live, _html} = live(conn, ~p"/about")

      assert index_live |> element("#about-#{about.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#about-#{about.id}")
    end
  end

  describe "Show" do
    setup [:create_about]

    test "displays about", %{conn: conn, about: about} do
      {:ok, _show_live, html} = live(conn, ~p"/about/#{about}")

      assert html =~ "Show About"
    end

    test "updates about within modal", %{conn: conn, about: about} do
      {:ok, show_live, _html} = live(conn, ~p"/about/#{about}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit About"

      assert_patch(show_live, ~p"/about/#{about}/show/edit")

      assert show_live
             |> form("#about-form", about: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#about-form", about: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/about/#{about}")

      html = render(show_live)
      assert html =~ "About updated successfully"
    end
  end
end
