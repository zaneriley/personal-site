defmodule Portfolio.GitHubWebhookHelpers do
  @moduledoc false

  import Plug.Conn

  @github_owner "zaneriley"
  @github_repo "personal-site-content"
  @main_ref "refs/heads/main"
  @webhook_path "/api/v1/content/push"

  @spec github_push_payload(keyword()) :: map()
  def github_push_payload(opts) do
    after_sha = Keyword.fetch!(opts, :after)
    repository_url = Keyword.fetch!(opts, :repository_url)
    ref = Keyword.get(opts, :ref, @main_ref)
    changes = Keyword.get(opts, :changes, %{})
    owner = Keyword.get(opts, :owner, @github_owner)
    repo = Keyword.get(opts, :repo, @github_repo)

    %{
      "ref" => ref,
      "after" => after_sha,
      "repository" => %{
        "clone_url" => repository_url,
        "ssh_url" => repository_url,
        "full_name" => "#{owner}/#{repo}",
        "name" => repo,
        "owner" => %{
          "id" => 1,
          "login" => owner,
          "name" => owner
        }
      },
      "commits" => [
        %{
          "id" => after_sha,
          "added" => changed_paths(changes, :added),
          "modified" => changed_paths(changes, :modified),
          "removed" => changed_paths(changes, :removed)
        }
      ],
      "sender" => %{
        "id" => 1,
        "login" => "octocat"
      }
    }
  end

  @spec github_webhook_path() :: String.t()
  def github_webhook_path, do: @webhook_path

  @spec github_webhook_signature(String.t()) :: String.t()
  def github_webhook_signature(encoded_payload) do
    secret = Application.fetch_env!(:github_webhook, :secret)
    digest = :crypto.mac(:hmac, :sha256, secret, encoded_payload)

    "sha256=" <> Base.encode16(digest, case: :lower)
  end

  @spec signed_github_webhook_conn(Plug.Conn.t(), map(), keyword()) ::
          {Plug.Conn.t(), String.t()}
  def signed_github_webhook_conn(conn, payload, opts \\ []) do
    event = Keyword.get(opts, :event, "push")
    delivery_id = Keyword.fetch!(opts, :delivery_id)
    encoded_payload = Jason.encode!(payload)

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-github-event", event)
      |> put_req_header("x-github-delivery", delivery_id)
      |> put_req_header(
        "x-hub-signature-256",
        github_webhook_signature(encoded_payload)
      )

    {conn, encoded_payload}
  end

  defp changed_paths(changes, key) when is_map(changes) do
    Map.get(changes, key) || Map.get(changes, Atom.to_string(key), [])
  end
end
