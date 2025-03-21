defmodule PortfolioWeb.Components.ColumnLayoutTest do
  use PortfolioWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias PortfolioWeb.Components.ColumnLayout

  describe "column_layout/1" do
    test "renders a grid layout with columns" do
      columns = [%{width: "1"}, %{width: "2"}]

      html =
        render_component(&ColumnLayout.column_layout/1, %{
          columns: columns,
          gap: "gap-6",
          class: "test-class"
        }) do
          %{
            column: [
              %{
                index: 0,
                inner_block: fn -> "Column 1 content" end
              },
              %{
                index: 1,
                inner_block: fn -> "Column 2 content" end
              }
            ]
          }
        end

      # Check that the grid container is rendered
      assert html =~ "grid gap-6 test-class"

      # Check that grid-template-columns style is set
      assert html =~ "grid-template-columns: 1fr 2fr"

      # Check that column content is included
      assert html =~ "Column 1 content"
      assert html =~ "Column 2 content"
    end

    test "renders with default gap when not specified" do
      html =
        render_component(&ColumnLayout.column_layout/1, %{
          columns: [%{width: "1"}]
        }) do
          %{
            column: [
              %{
                index: 0,
                inner_block: fn -> "Content" end
              }
            ]
          }
        end

      assert html =~ "grid gap-4"
    end
  end
end
