defmodule PortfolioWeb.EndpointWebhookTest do
  use PortfolioWeb.ConnCase, async: true

  @webhook_path "/api/v1/content/push"

  describe "GitHub webhook plug" do
    test "accepts a signed webhook request through the endpoint", %{conn: conn} do
      payload = payload_with_no_relevant_changes()
      encoded_payload = Jason.encode!(payload)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-hub-signature-256", signature(encoded_payload))
        |> post(@webhook_path, encoded_payload)

      assert response(conn, :ok) == "OK"
    end

    test "rejects a webhook request signed with the wrong secret", %{conn: conn} do
      payload = payload_with_no_relevant_changes()
      encoded_payload = Jason.encode!(payload)
      wrong_signature = "sha256=" <> String.duplicate("0", 64)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-hub-signature-256", wrong_signature)
        |> post(@webhook_path, encoded_payload)

      assert response(conn, :forbidden) == "Forbidden"
    end
  end

  defp payload_with_no_relevant_changes do
    %{
      "ref" => "refs/heads/main",
      "commits" => [
        %{
          "added" => ["README.txt"],
          "modified" => []
        }
      ]
    }
  end

  defp signature(encoded_payload) do
    secret = Application.fetch_env!(:github_webhook, :secret)
    digest = :crypto.mac(:hmac, :sha256, secret, encoded_payload)

    "sha256=" <> Base.encode16(digest, case: :lower)
  end
end
