defmodule PortfolioWeb.Components.ColumnLayout do
  @moduledoc """
  A component for rendering content in a multi-column layout.

  This component supports various column widths and gap sizes, making it
  flexible for different layout needs in markdown content.

  ## Examples

      <.column_layout columns={[%{width: "1"}, %{width: "2"}]} gap="gap-4">
        <:column index={0}>
          Content for first column
        </:column>
        <:column index={1}>
          Content for second column (twice as wide)
        </:column>
      </.column_layout>
  """

  use Phoenix.Component

  use Portfolio.Content.MarkdownRendering.Components.Definition,
    type: :column_layout,
    function: :column_layout,
    description: "A component for rendering content in a multi-column layout",
    attributes: %{
      columns: %{
        type: :list,
        required: true,
        description: "List of column specifications with width"
      },
      gap: %{
        type: :string,
        required: false,
        default: "gap-4",
        description: "CSS class for gap between columns"
      },
      class: %{
        type: :string,
        required: false,
        default: "",
        description: "Additional CSS classes"
      }
    },
    slots: [
      %{
        name: :column,
        description: "Content for a specific column",
        attributes: %{
          index: %{
            type: :integer,
            required: true,
            description: "Index of the column this content should appear in"
          }
        }
      }
    ],
    examples: [
      """
      <.column_layout columns={[%{width: "1"}, %{width: "2"}]} gap="gap-4">
        <:column index={0}>Left column content</:column>
        <:column index={1}>Right column content (twice as wide)</:column>
      </.column_layout>
      """
    ]

  @doc """
  Renders content in a multi-column layout.

  ## Attributes

    * `columns` - A list of maps with width specifications for each column
    * `gap` - CSS class for gap between columns, default "gap-4"
    * `class` - Additional CSS classes to apply to the container
  """
  attr :columns, :list, required: true, doc: "List of column specifications"
  attr :gap, :string, default: "gap-4", doc: "Gap between columns"
  attr :class, :string, default: "", doc: "Additional CSS classes"

  slot :column, required: true do
    attr :index, :integer, required: true
  end

  def column_layout(assigns) do
    # Calculate total columns for grid template
    total_width =
      assigns.columns
      |> Enum.map(fn col ->
        width = Map.get(col, :width, "1")

        case Integer.parse(width) do
          {num, ""} -> num
          _ -> 1
        end
      end)
      |> Enum.sum()

    # Prepare grid template columns CSS
    grid_template =
      Enum.map_join(assigns.columns, " ", fn col ->
        width = Map.get(col, :width, "1")
        "#{width}fr"
      end)

    assigns = assign(assigns, :grid_template, grid_template)

    ~H"""
    <div
      class={"grid #{@gap} #{@class}"}
      style={"grid-template-columns: #{@grid_template}"}
    >
      <%= for {_col, i} <- Enum.with_index(@columns) do %>
        <div class={column_class(@columns, i)}>
          <%= for slot <- @column, slot.index == i do %>
            <%= render_slot(slot) %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper to generate column classes based on width
  defp column_class(columns, index) when index < length(columns) do
    column = Enum.at(columns, index)
    _width = Map.get(column, :width, "1")

    # Add more responsive classes as needed
    ""
  end
end
