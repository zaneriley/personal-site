defmodule Portfolio.Content.Remote.GitHubStatusReporter do
  @moduledoc """
  Publishes content publication verdicts as GitHub commit statuses.
  """

  alias Portfolio.Content.Schemas.PublicationLedgerEntry

  require Logger

  @repo_part "[A-Za-z0-9_.-]+"
  @github_repo_url Regex.compile!(
                     "\\Ahttps://github\\.com/(?<owner>#{@repo_part})/" <>
                       "(?<repo>#{@repo_part})(?:\\.git)?/?\\z"
                   )
  @github_ssh_url Regex.compile!(
                    "\\Agit@github\\.com:(?<owner>#{@repo_part})/" <>
                      "(?<repo>#{@repo_part})(?:\\.git)?\\z"
                  )
  @github_ssh_scheme_url Regex.compile!(
                           "\\Assh://git@github\\.com/" <>
                             "(?<owner>#{@repo_part})/" <>
                             "(?<repo>#{@repo_part})(?:\\.git)?\\z"
                         )
  @description_limit 140

  @type report_config :: %{
          token: String.t(),
          owner: String.t(),
          repo: String.t(),
          context: String.t(),
          api_url: String.t(),
          client: module(),
          target_url: String.t()
        }

  @doc """
  Reports a publication verdict to GitHub.
  """
  @spec report(PublicationLedgerEntry.t(), keyword()) ::
          :ok | :disabled | {:error, term()}
  def report(%PublicationLedgerEntry{} = entry, opts \\ []) do
    with {:ok, config} <- report_config(entry, opts),
         payload <- status_payload(entry, config) do
      config.client.create_status(
        config.owner,
        config.repo,
        entry.content_sha,
        payload,
        token: config.token,
        api_url: config.api_url
      )
    end
  end

  @doc """
  Reports a publication verdict and logs failures without failing publication.
  """
  @spec report_and_log(PublicationLedgerEntry.t(), keyword()) :: :ok
  def report_and_log(%PublicationLedgerEntry{} = entry, opts \\ []) do
    case report(entry, opts) do
      :ok ->
        :ok

      :disabled ->
        log_disabled(entry)

        :ok

      {:error, reason} ->
        Logger.error(
          "Failed to report content publication status to GitHub: #{inspect(reason)}"
        )

        :ok
    end
  end

  defp report_config(entry, opts) do
    with {:ok, token} <- github_token(opts),
         {:ok, {owner, repo}} <- github_repo(entry, opts),
         {:ok, target_url} <- target_url(entry, opts) do
      {:ok,
       %{
         token: token,
         owner: owner,
         repo: repo,
         context: github_status_context(opts),
         api_url: github_status_api_url(opts),
         client: github_status_client(opts),
         target_url: target_url
       }}
    end
  end

  defp log_disabled(entry) do
    message = "GitHub status reporting disabled for #{entry.content_sha}"

    if Application.get_env(:portfolio, :environment, nil) == :prod do
      Logger.warning(message)
    else
      Logger.info(message)
    end
  end

  defp github_token(opts) do
    token =
      Keyword.get(opts, :github_token) ||
        Application.get_env(:portfolio, :github_token, nil)

    cond do
      is_binary(token) and token != "" -> {:ok, token}
      is_nil(token) or token == "" -> :disabled
    end
  end

  defp github_repo(entry, opts) do
    owner =
      Keyword.get(opts, :github_status_owner) ||
        Application.get_env(:portfolio, :github_status_owner, nil)

    repo =
      Keyword.get(opts, :github_status_repo) ||
        Application.get_env(:portfolio, :github_status_repo, nil)

    if present?(owner) and present?(repo) do
      {:ok, {owner, repo}}
    else
      entry
      |> repository_url(opts)
      |> parse_github_repo()
    end
  end

  defp repository_url(entry, opts) do
    Keyword.get(opts, :repository) ||
      entry.repository ||
      Application.get_env(:portfolio, :content_repo_url, nil)
  end

  defp parse_github_repo(url) when is_binary(url) do
    Enum.find_value(
      [@github_repo_url, @github_ssh_url, @github_ssh_scheme_url],
      {:error, :unsupported_github_repository_url},
      fn pattern ->
        case Regex.named_captures(pattern, url) do
          %{"owner" => owner, "repo" => repo} ->
            {:ok, {owner, String.replace_suffix(repo, ".git", "")}}

          nil ->
            nil
        end
      end
    )
  end

  defp parse_github_repo(nil), do: {:error, :missing_github_repository}

  defp target_url(entry, opts) do
    link_builder =
      Keyword.get(opts, :publication_debug_link_builder) ||
        Application.get_env(
          :portfolio,
          :publication_debug_link_builder,
          PortfolioWeb.ContentPublicationDebugLink
        )

    {:ok, link_builder.signed_url(entry)}
  end

  defp github_status_context(opts) do
    Keyword.get(opts, :github_status_context) ||
      Application.get_env(
        :portfolio,
        :github_status_context,
        "content/publication"
      )
  end

  defp github_status_api_url(opts) do
    Keyword.get(opts, :github_status_api_url) ||
      Application.get_env(
        :portfolio,
        :github_status_api_url,
        "https://api.github.com"
      )
  end

  defp github_status_client(opts) do
    Keyword.get(opts, :github_status_client) ||
      Application.get_env(
        :portfolio,
        :github_status_client,
        Portfolio.Content.Remote.GitHubStatusClient.Req
      )
  end

  defp status_payload(entry, config) do
    %{
      state: github_state(entry.status),
      context: config.context,
      description: entry |> description() |> truncate_description(),
      target_url: config.target_url
    }
  end

  defp github_state(status)
       when status in ["accepted", "duplicate", "ignored", "rollback"] do
    "success"
  end

  defp github_state("rejected"), do: "failure"

  defp description(%PublicationLedgerEntry{status: "accepted"}) do
    "Content accepted and live"
  end

  defp description(%PublicationLedgerEntry{status: "duplicate"}) do
    "Duplicate content delivery ignored"
  end

  defp description(%PublicationLedgerEntry{status: "ignored", reason: reason})
       when is_binary(reason) and reason != "" do
    reason
  end

  defp description(%PublicationLedgerEntry{status: "ignored"}) do
    "No relevant content changes"
  end

  defp description(%PublicationLedgerEntry{status: "rejected", reason: reason})
       when is_binary(reason) and reason != "" do
    reason
  end

  defp description(%PublicationLedgerEntry{status: "rejected"}) do
    "Content rejected; last-good content remains live"
  end

  defp description(%PublicationLedgerEntry{status: "rollback"}) do
    "Content rolled back to last-good"
  end

  defp truncate_description(description)
       when byte_size(description) <= @description_limit do
    description
  end

  defp truncate_description(description) do
    description
    |> String.slice(0, @description_limit - 3)
    |> Kernel.<>("...")
  end

  defp present?(value), do: is_binary(value) and value != ""
end
