defmodule PortfolioWeb.CanonicalUrlTest do
  use ExUnit.Case, async: false
  alias PortfolioWeb.CanonicalUrl

  setup do
    previous = Application.get_env(:portfolio, :canonical_origin)

    on_exit(fn ->
      if previous do
        Application.put_env(:portfolio, :canonical_origin, previous)
      else
        Application.delete_env(:portfolio, :canonical_origin)
      end
    end)

    Application.delete_env(:portfolio, :canonical_origin)
    :ok
  end

  describe "for_path/1" do
    test "returns nil when :canonical_origin is unset" do
      assert CanonicalUrl.for_path("/en/note/foo") == nil
    end

    test "returns nil when :canonical_origin is explicitly nil" do
      Application.put_env(:portfolio, :canonical_origin, nil)
      assert CanonicalUrl.for_path("/en/note/foo") == nil
    end

    test "returns origin <> path when configured" do
      Application.put_env(
        :portfolio,
        :canonical_origin,
        "https://zaneriley.com"
      )

      assert CanonicalUrl.for_path("/en/note/foo") ==
               "https://zaneriley.com/en/note/foo"
    end

    test "preserves the locale segment in the canonical URL" do
      Application.put_env(
        :portfolio,
        :canonical_origin,
        "https://zaneriley.com"
      )

      assert CanonicalUrl.for_path("/ja/note/foo") ==
               "https://zaneriley.com/ja/note/foo"
    end

    test "raises when given a non-root-relative path" do
      Application.put_env(
        :portfolio,
        :canonical_origin,
        "https://zaneriley.com"
      )

      assert_raise FunctionClauseError, fn ->
        CanonicalUrl.for_path("relative/path")
      end
    end
  end
end
