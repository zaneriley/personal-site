defmodule PortfolioWeb.Components.PortfolioItemList do
  @moduledoc """
  Renders a list of items, intended for full ist of different schemas (case studies, notes, etc)

  """
  use Phoenix.Component
  import PortfolioWeb.Gettext
  import PortfolioWeb.Components.Typography
  import PortfolioWeb.Components.ContentMetadata

  @doc """
  Renders a list of portfolio items.

  ## Examples

      <.portfolio_item_list
        items={@items}
        navigate_to={&Routes.item_show_path(@socket, :show, @user_locale, &1.url)}
      />
  """
  attr :items, :list, required: true
  attr :navigate_to, :any, required: true

  def portfolio_item_list(assigns) do
    ~H"""
    <div class="portfolio-item-list">
      <ul class="space-y-md">
        <%= for {_id, item} <- @items do %>
          <li class="group rounded-lg overflow-hidden">
            <.link navigate={@navigate_to.(item)} class="block p-4">
              <div class="flex justify-between items-start mb-2">
                <.typography tag="h3" size="1xl" font="cardinal">
                  <%= item.title %>
                </.typography>
                <.typography tag="span" size="1xs" font="cheee">
                  <%= format_date(item.published_at) %>
                </.typography>
              </div>
              <.typography tag="p" size="1xs" class="mb-2">
                <%= item.introduction %>
              </.typography>
            <.content_metadata
              read_time={
                item.translations["read_time"] || item.read_time
              }
              word_count={
                item.translations["word_count"] || item.word_count
              }
              character_count={
                item.translations["word_count"] || item.word_count
              }

            />
            </.link>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  defp format_date(nil), do: ""

  defp format_date(%NaiveDateTime{} = date),
    do: NaiveDateTime.to_date(date) |> format_date()

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%b %d, %Y")
  defp format_date(_), do: ""
end
