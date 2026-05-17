defmodule PortfolioWeb.Plugs.Noindex do
  @moduledoc """
  Emits `X-Robots-Tag: noindex, nofollow` when `:noindex` runtime config is
  truthy. Preview deploys set `:noindex` via `runtime.exs` from `PHX_NOINDEX`.

  Reads `Application.get_env/3` in `call/2`, not `init/1` or compile time:
  router plug `init/1` can run before release runtime config fully resolves,
  so the live value is read per-request.
  """
  @behaviour Plug

  import Plug.Conn

  @header_name "x-robots-tag"
  @header_value "noindex, nofollow"

  @impl Plug
  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @impl Plug
  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    if Application.get_env(:portfolio, :noindex, false) do
      put_resp_header(conn, @header_name, @header_value)
    else
      conn
    end
  end
end
