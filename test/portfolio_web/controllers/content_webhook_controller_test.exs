defmodule PortfolioWeb.ContentWebhookControllerTest do
  use PortfolioWeb.ConnCase
  import PortfolioWeb.Router.Helpers, only: [content_webhook_path: 2]

  @valid_payload %{
    "repository" => %{
      "clone_url" => "https://github.com/zaneriley/personal-site-content.git"
    },
    "ref" => "refs/heads/main",
    "before" => "9dc555075d3ddea2ef7ee254d17c7573e223a24b",
    "after" => "52239dee266c5ddd2f6385538653753a32a32b02",
    "commits" => [
      %{
        "id" => "52239dee266c5ddd2f6385538653753a32a32b02",
        "message" => "Update case studies",
        "added" => [
          "priv/content/case-study/en/marketing-game-design-of-oddity.md"
        ],
        "modified" => [
          "priv/content/case-study/en/building-design-system-nerdwallet-financial-advice.md",
          "priv/content/case-study/en/improving-ecommerce-flow-for-startup.md"
        ]
      }
    ]
  }

  @no_changes_payload %{
    "repository" => %{"clone_url" => "https://github.com/user/repo.git"},
    "commits" => []
  }

  describe "handle_push/2" do
    test "successfully processes valid payload with changes", %{conn: conn} do
      conn =
        post(conn, content_webhook_path(conn, :handle_push), %{
          "payload" => @valid_payload
        })

      assert conn.status == 200

      assert json_response(conn, 200) == %{
               "message" => "Content update process initiated successfully"
             }
    end

    test "handles payload with no relevant changes", %{conn: conn} do
      conn =
        post(conn, content_webhook_path(conn, :handle_push), %{
          "payload" => @no_changes_payload
        })

      assert conn.status == 200

      assert json_response(conn, 200) == %{
               "message" => "No relevant changes detected"
             }
    end

    test "handles payload with missing repository information", %{conn: conn} do
      invalid_payload = Map.delete(@valid_payload, "repository")

      conn =
        post(conn, content_webhook_path(conn, :handle_push), %{
          "payload" => invalid_payload
        })

      assert conn.status == 400

      assert json_response(conn, 400) == %{
               "error" => "Invalid payload",
               "message" => "Missing repository information"
             }
    end

    test "handles payload with missing commits information", %{conn: conn} do
      invalid_payload = Map.delete(@valid_payload, "commits")

      conn =
        post(conn, content_webhook_path(conn, :handle_push), %{
          "payload" => invalid_payload
        })

      assert conn.status == 400

      assert json_response(conn, 400) == %{
               "error" => "Invalid payload",
               "message" => "Missing commits information"
             }
    end

    test "handles completely invalid payload", %{conn: conn} do
      conn =
        post(conn, content_webhook_path(conn, :handle_push), %{"payload" => %{}})

      assert conn.status == 400

      assert json_response(conn, 400) == %{
               "error" => "Invalid payload",
               "message" => "Missing repository information"
             }
    end
  end
end
