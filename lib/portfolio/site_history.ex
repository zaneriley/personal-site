defmodule Portfolio.SiteHistory do
  @moduledoc """
  Facts about the site's own history, shown in the footer's Server sheet:
  how many changes the codebase has had and when the latest one landed.

  Sources, first answer wins:

    1. `SITE_CHANGE_COUNT` and `SITE_LAST_CHANGE_AT` (ISO 8601) in the
       environment. Release images ship without `.git`, so the build or deploy
       sets these.
    2. The git checkout the app runs from (local dev).

  When no source answers, the fact is `nil` and the footer leaves its row out.
  The card never shows an invented value.

  Facts are read once per node and kept in `:persistent_term`, so a running
  node reports the code it is running.
  """

  @key {__MODULE__, :facts}

  @type facts :: %{
          changes: pos_integer() | nil,
          last_change_at: DateTime.t() | nil
        }

  @doc "Returns the cached history facts, reading them on first use."
  @spec facts() :: facts()
  def facts do
    case :persistent_term.get(@key, nil) do
      nil ->
        facts = read()
        :persistent_term.put(@key, facts)
        facts

      facts ->
        facts
    end
  end

  @doc """
  Reads the facts without the cache. `env` and `git` are injectable for tests:
  `env` takes a variable name, `git` takes `:count` or `:last_change`; both
  return a string or `nil`.
  """
  @spec read((String.t() -> String.t() | nil), (atom() -> String.t() | nil)) ::
          facts()
  def read(env \\ &System.get_env/1, git \\ &git/1) do
    %{
      changes:
        parse_count(env.("SITE_CHANGE_COUNT")) || parse_count(git.(:count)),
      last_change_at:
        parse_time(env.("SITE_LAST_CHANGE_AT")) ||
          parse_time(git.(:last_change))
    }
  end

  defp parse_count(nil), do: nil

  defp parse_count(value) do
    case Integer.parse(String.trim(value)) do
      {count, ""} when count > 0 -> count
      _ -> nil
    end
  end

  defp parse_time(nil), do: nil

  defp parse_time(value) do
    case DateTime.from_iso8601(String.trim(value)) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end

  defp git(:count), do: run_git(["rev-list", "--count", "HEAD"])
  defp git(:last_change), do: run_git(["log", "-1", "--format=%cI"])

  defp run_git(args) do
    case System.cmd("git", args, stderr_to_stdout: true) do
      {out, 0} -> String.trim(out)
      _ -> nil
    end
  rescue
    # git missing from PATH, or no checkout at all.
    _ -> nil
  end
end
