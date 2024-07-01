defmodule PortfolioWeb.Components.PortfolioItemList do
  @moduledoc """
  Renders a list of items, intended for full ist of different schemas (case studies, notes, etc)

  """
  use Phoenix.Component
  import PortfolioWeb.Gettext

  def portfolio_item_list(assigns) do
    ~H"""
    <div class="portfolio-item-list">
      <table>
        <thead>
          <tr>
            <th>Title</th>
            <th>Details</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <%= for {_id, item} <- @items do %>
            <tr>
              <td>
                <h3><%= item.title %></h3>
                <p>
                  <%= item.introduction || String.slice(item.content, 0, 100) %>...
                </p>
              </td>
              <td>
                <ul>
                  <li>
                    <%= ngettext(
                      "%{count} min read",
                      "%{count} min read",
                      item.read_time,
                      count: item.read_time
                    ) %>
                  </li>
                </ul>
              </td>
              <td>
                <%= render_slot(@action, item) %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
