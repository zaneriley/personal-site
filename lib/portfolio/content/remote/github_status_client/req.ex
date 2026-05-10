defmodule Portfolio.Content.Remote.GitHubStatusClient.Req do
  @moduledoc """
  Req-backed GitHub commit status client.
  """

  @behaviour Portfolio.Content.Remote.GitHubStatusClient

  alias Portfolio.Content.Remote.GitHubStatusClient

  @api_version "2026-03-10"
  @user_agent "portfolio-content-publisher"

  @impl true
  @spec create_status(
          String.t(),
          String.t(),
          String.t(),
          GitHubStatusClient.status_payload(),
          keyword()
        ) :: :ok | {:error, term()}
  def create_status(owner, repo, sha, payload, opts) do
    token = Keyword.fetch!(opts, :token)
    api_url = opts |> Keyword.fetch!(:api_url) |> String.trim_trailing("/")

    request_opts = [
      url: "#{api_url}/repos/#{owner}/#{repo}/statuses/#{sha}",
      headers: [
        {"accept", "application/vnd.github+json"},
        {"authorization", "Bearer #{token}"},
        {"x-github-api-version", @api_version},
        {"user-agent", @user_agent}
      ],
      json: payload
    ]

    case Req.post(request_opts) do
      {:ok, %Req.Response{status: status}} when status in 200..299 ->
        :ok

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:github_status_failed, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
