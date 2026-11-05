defmodule PortfolioWeb.Components.Action do
  @moduledoc """
  The light layer for the `.action` button primitive (assets/css/_action.css).

  Render it as the first child of any element with the `action` class. It is
  decorative and hidden from assistive technology.
  """
  use Phoenix.Component

  @spec light(map()) :: Phoenix.LiveView.Rendered.t()
  def light(assigns) do
    ~H"""
    <span class="action-light" aria-hidden="true">
      <span class="action-light-ring"><span class="action-light-wave"></span></span>
    </span>
    """
  end
end
