defmodule PortfolioWeb.Plugs.NoindexTest do
  use ExUnit.Case, async: false
  import Plug.Test
  alias PortfolioWeb.Plugs.Noindex

  setup do
    previous = Application.get_env(:portfolio, :noindex)

    on_exit(fn ->
      if previous == nil do
        Application.delete_env(:portfolio, :noindex)
      else
        Application.put_env(:portfolio, :noindex, previous)
      end
    end)

    :ok
  end

  describe "call/2" do
    test "emits X-Robots-Tag: noindex, nofollow when :noindex is true" do
      Application.put_env(:portfolio, :noindex, true)
      conn = conn(:get, "/") |> Noindex.call(Noindex.init([]))

      assert Plug.Conn.get_resp_header(conn, "x-robots-tag") == [
               "noindex, nofollow"
             ]
    end

    test "does not emit the header when :noindex is false" do
      Application.put_env(:portfolio, :noindex, false)
      conn = conn(:get, "/") |> Noindex.call(Noindex.init([]))

      assert Plug.Conn.get_resp_header(conn, "x-robots-tag") == []
    end

    test "does not emit the header when :noindex is unset" do
      Application.delete_env(:portfolio, :noindex)
      conn = conn(:get, "/") |> Noindex.call(Noindex.init([]))

      assert Plug.Conn.get_resp_header(conn, "x-robots-tag") == []
    end
  end
end
