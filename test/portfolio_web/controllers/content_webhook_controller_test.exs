defmodule PortfolioWeb.ContentWebhookControllerTest do
  use PortfolioWeb.ConnCase, async: true

  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Repo

  import Portfolio.ContentRepoHelpers

  describe "handle_webhook/3" do
    test "triggers update for push event with relevant changes", %{conn: conn} do
      source_repo = tmp_dir!("webhook-source")
      clone_path = tmp_dir!("webhook-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/webhook-note/en.md", url: "webhook-note")
      target_sha = commit!(source_repo, "publish webhook note")

      payload = %{
        "ref" => "refs/heads/main",
        "after" => target_sha,
        "repository" => %{"clone_url" => source_repo},
        "commits" => [
          %{
            "added" => ["notes/webhook-note/en.md"],
            "modified" => []
          }
        ],
        "sender" => %{"id" => 1, "login" => "octocat"}
      }

      assert {:ok, result} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 content_repo_url: source_repo,
                 content_base_path: clone_path
               )

      assert result.promoted == [
               Path.expand("notes/webhook-note/en.md", clone_path)
             ]

      assert %Note{} = Repo.get_by(Note, url: "webhook-note")
    end

    test "does not trigger update for push event without relevant changes", %{
      conn: conn
    } do
      payload = %{
        "ref" => "refs/heads/main",
        "after" => String.duplicate("a", 40),
        "repository" => %{"clone_url" => "https://example.test/content.git"},
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
                 content_repo_url: "https://example.test/content.git"
               )
    end

    test "rejects non-push event", %{conn: conn} do
      payload = %{
        "action" => "opened",
        "issue" => %{"number" => 1347},
        "repository" => %{"clone_url" => "https://example.test/content.git"},
        "sender" => %{"id" => 1, "login" => "octocat"}
      }

      assert {:error, "Invalid or unsupported event type"} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 content_repo_url: "https://example.test/content.git"
               )
    end

    test "rejects invalid payload", %{conn: conn} do
      invalid_payload = %{"invalid" => "data"}

      assert {:error, "Invalid or unsupported event type"} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 invalid_payload,
                 content_repo_url: "https://example.test/content.git"
               )
    end

    test "rejects pushes from unexpected refs", %{conn: conn} do
      payload = %{
        "ref" => "refs/heads/draft",
        "after" => String.duplicate("a", 40),
        "repository" => %{"clone_url" => "https://example.test/content.git"},
        "commits" => [%{"added" => ["notes/new/en.md"]}]
      }

      assert {:error, "Unexpected ref: refs/heads/draft"} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 content_repo_url: "https://example.test/content.git"
               )
    end

    test "rejects pushes from unexpected repositories", %{conn: conn} do
      payload = %{
        "ref" => "refs/heads/main",
        "after" => String.duplicate("a", 40),
        "repository" => %{"clone_url" => "https://example.test/other.git"},
        "commits" => [%{"added" => ["notes/new/en.md"]}]
      }

      assert {:error, "Unexpected repository"} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 content_repo_url: "https://example.test/content.git"
               )
    end

    test "rejects non-hex after shas", %{conn: conn} do
      payload = %{
        "ref" => "refs/heads/main",
        "after" => String.duplicate("z", 40),
        "repository" => %{"clone_url" => "https://example.test/content.git"},
        "commits" => [%{"added" => ["notes/new/en.md"]}]
      }

      assert {:error, "Invalid after SHA"} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 content_repo_url: "https://example.test/content.git"
               )
    end
  end
end
