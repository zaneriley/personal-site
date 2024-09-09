defmodule PortfolioWeb.ContentWebhookControllerTest do
  use PortfolioWeb.ConnCase
  use ExUnit.Case, async: true

  @content_repo_url "https://github.com/zaneriley/personal-site-content.git"

  setup do
    Application.put_env(:portfolio, :content_repo_url, @content_repo_url)
    :ok
  end

  describe "handle_webhook/3" do
    test "triggers update for push event with relevant changes", %{conn: conn} do
      payload = %{
        "ref" => "refs/heads/main",
        "repository" => %{"clone_url" => @content_repo_url},
        "commits" => [
          %{
            "added" => ["priv/content/case-study/en/new-case-study.md"],
            "modified" => ["priv/content/case-study/en/existing-case-study.md"]
          }
        ],
        "sender" => %{"id" => 1, "login" => "octocat"}
      }

      assert {:ok, :updated} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 []
               )
    end

    test "does not trigger update for push event without relevant changes", %{
      conn: conn
    } do
      payload = %{
        "ref" => "refs/heads/main",
        "repository" => %{"clone_url" => @content_repo_url},
        "commits" => [
          %{
            "added" => ["irrelevant-file.txt"],
            "modified" => [".gitignore"]
          }
        ],
        "sender" => %{"id" => 1, "login" => "octocat"}
      }

      assert {:ok, :no_relevant_changes} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 []
               )
    end

    test "rejects non-push event", %{conn: conn} do
      payload = %{
        "action" => "opened",
        "issue" => %{"number" => 1347},
        "repository" => %{"clone_url" => @content_repo_url},
        "sender" => %{"id" => 1, "login" => "octocat"}
      }

      assert {:error, "Invalid or unsupported event type"} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 []
               )
    end

    test "rejects invalid payload", %{conn: conn} do
      invalid_payload = %{"invalid" => "data"}

      assert {:error, "Invalid or unsupported event type"} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 invalid_payload,
                 []
               )
    end
  end
end
