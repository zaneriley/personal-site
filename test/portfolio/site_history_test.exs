defmodule Portfolio.SiteHistoryTest do
  use ExUnit.Case, async: true

  alias Portfolio.SiteHistory

  defp env(map), do: &Map.get(map, &1)

  test "environment values win over git" do
    facts =
      SiteHistory.read(
        env(%{
          "SITE_CHANGE_COUNT" => "503",
          "SITE_LAST_CHANGE_AT" => "2026-11-04T14:05:00+09:00"
        }),
        fn _ -> flunk("git should not be asked") end
      )

    assert facts.changes == 503
    assert facts.last_change_at == ~U[2026-11-04 05:05:00Z]
  end

  test "falls back to git when the environment is empty" do
    git = fn
      :count -> "42\n"
      :last_change -> "2026-11-02T10:00:00+00:00"
    end

    assert SiteHistory.read(env(%{}), git) == %{
             changes: 42,
             last_change_at: ~U[2026-11-02 10:00:00Z]
           }
  end

  test "unreadable or missing sources give nil, never a made-up value" do
    git = fn _ -> nil end

    assert SiteHistory.read(env(%{}), git) == %{
             changes: nil,
             last_change_at: nil
           }

    assert SiteHistory.read(
             env(%{
               "SITE_CHANGE_COUNT" => "lots",
               "SITE_LAST_CHANGE_AT" => "soon"
             }),
             git
           ) == %{changes: nil, last_change_at: nil}

    assert SiteHistory.read(env(%{"SITE_CHANGE_COUNT" => "0"}), git).changes ==
             nil
  end
end
