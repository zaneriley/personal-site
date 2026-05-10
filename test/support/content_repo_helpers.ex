defmodule Portfolio.ContentRepoHelpers do
  @moduledoc false

  @git_env [
    {"GIT_TERMINAL_PROMPT", "0"},
    {"GITHUB_TOKEN", nil},
    {"RELEASE_PLEASE_TOKEN", nil}
  ]

  @spec tmp_dir!(String.t()) :: String.t()
  def tmp_dir!(name) do
    path =
      Path.join([
        System.tmp_dir!(),
        "portfolio-content-#{name}-#{System.unique_integer([:positive])}"
      ])

    File.rm_rf!(path)
    File.mkdir_p!(path)
    path
  end

  @spec init_repo!(String.t()) :: String.t()
  def init_repo!(path) do
    File.mkdir_p!(path)
    git!(path, ["init", "--initial-branch=main"])
    git!(path, ["config", "user.email", "portfolio@example.test"])
    git!(path, ["config", "user.name", "Portfolio Test"])
    path
  end

  @spec write_note!(String.t(), String.t(), keyword()) :: String.t()
  def write_note!(repo_path, relative_path, opts \\ []) do
    title = Keyword.get(opts, :title, "Published Note")
    url = Keyword.get(opts, :url, "published-note")
    body = Keyword.get(opts, :body, "# Published Note\n\nHello.")
    published_at = Keyword.get(opts, :published_at, "2024-07-27T14:30:00Z")
    is_draft = Keyword.get(opts, :is_draft, false)

    write_file!(
      repo_path,
      relative_path,
      """
      ---
      title: "#{title}"
      url: "#{url}"
      introduction: "Intro"
      #{aliases_frontmatter(opts)}
      #{share_preview_frontmatter(opts)}
      published_at: "#{published_at}"
      is_draft: #{is_draft}
      ---

      #{body}
      """
    )
  end

  @spec write_invalid_note!(String.t(), String.t()) :: String.t()
  def write_invalid_note!(repo_path, relative_path) do
    write_file!(
      repo_path,
      relative_path,
      """
      ---
      title: "Broken Note"
      url: "published-note"
      is_draft: false
      --

      # Malformed frontmatter delimiter
      """
    )
  end

  @spec write_file!(String.t(), String.t(), String.t()) :: String.t()
  def write_file!(repo_path, relative_path, content) do
    path = Path.join(repo_path, relative_path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
    path
  end

  @spec delete_file!(String.t(), String.t()) :: :ok
  def delete_file!(repo_path, relative_path) do
    repo_path
    |> Path.join(relative_path)
    |> File.rm!()
  end

  @spec commit!(String.t(), String.t()) :: String.t()
  def commit!(repo_path, message) do
    git!(repo_path, ["add", "."])
    git!(repo_path, ["commit", "-m", message])
    rev_parse!(repo_path, "HEAD")
  end

  @spec rev_parse!(String.t(), String.t()) :: String.t()
  def rev_parse!(repo_path, rev) do
    repo_path
    |> git!(["rev-parse", rev])
    |> String.trim()
  end

  @spec git!(String.t(), [String.t()]) :: String.t()
  def git!(repo_path, args) do
    case System.cmd("git", args,
           cd: repo_path,
           env: @git_env,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        output

      {output, code} ->
        raise "git #{Enum.join(args, " ")} failed with #{code}: #{output}"
    end
  end

  defp share_preview_frontmatter(opts) do
    opts
    |> Keyword.take([
      :share_title,
      :share_description,
      :share_image_direction,
      :share_image_alt
    ])
    |> Enum.map_join("\n", fn {key, value} ->
      "#{key}: #{inspect(value)}"
    end)
  end

  defp aliases_frontmatter(opts) do
    case Keyword.get(opts, :aliases, []) do
      [] ->
        ""

      aliases ->
        items = Enum.map_join(aliases, "\n", &"  - #{inspect(&1)}")
        "aliases:\n#{items}"
    end
  end
end
