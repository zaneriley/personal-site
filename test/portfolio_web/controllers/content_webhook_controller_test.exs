defmodule PortfolioWeb.ContentWebhookControllerTest do
  use PortfolioWeb.ConnCase, async: true

  import Mox

  alias Portfolio.Content
  alias Portfolio.Content.Remote.GitHubStatusClient
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Repo

  import Portfolio.ContentRepoHelpers

  setup :verify_on_exit!

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

      expect(GitHubStatusClient.Mock, :create_status, fn
        "zaneriley", "personal-site-content", ^target_sha, payload, _opts ->
          assert payload.state == "success"
          assert payload.description == "Content accepted and live"
          assert payload.target_url =~ "/ops/content/publications/"

          :ok
      end)

      opts =
        [
          content_repo_url: source_repo,
          content_base_path: clone_path,
          github_delivery_id: "webhook-delivery-relevant"
        ] ++ github_status_opts()

      assert {:ok, result} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 opts
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

      expect(GitHubStatusClient.Mock, :create_status, fn
        "zaneriley", "personal-site-content", sha, payload, _opts ->
          assert sha == String.duplicate("a", 40)
          assert payload.state == "success"
          assert payload.description == "No relevant content changes"
          assert payload.target_url =~ "/ops/content/publications/"

          :ok
      end)

      assert {:ok, :no_relevant_changes} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 [
                   content_repo_url: "https://example.test/content.git",
                   github_delivery_id: "webhook-delivery-ignored"
                 ] ++ github_status_opts()
               )

      assert %{
               status: "ignored",
               reason: "No relevant content changes"
             } = Content.get_publication_verdict(String.duplicate("a", 40))
    end

    test "reports a failed status for rejected content pushes", %{conn: conn} do
      source_repo = tmp_dir!("webhook-rejected-source")
      clone_path = tmp_dir!("webhook-rejected-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_invalid_note!(source_repo, "notes/webhook-broken/en.md")
      target_sha = commit!(source_repo, "publish broken webhook note")

      payload = %{
        "ref" => "refs/heads/main",
        "after" => target_sha,
        "repository" => %{"clone_url" => source_repo},
        "commits" => [
          %{
            "added" => ["notes/webhook-broken/en.md"],
            "modified" => []
          }
        ],
        "sender" => %{"id" => 1, "login" => "octocat"}
      }

      expect(GitHubStatusClient.Mock, :create_status, fn
        "zaneriley", "personal-site-content", ^target_sha, payload, _opts ->
          assert payload.state == "failure"
          assert payload.description == "Content promotion failed"
          assert payload.target_url =~ "/ops/content/publications/"

          :ok
      end)

      opts =
        [
          content_repo_url: source_repo,
          content_base_path: clone_path,
          github_delivery_id: "webhook-delivery-rejected"
        ] ++ github_status_opts()

      assert {:error, ~s(Update failed: "Content promotion failed")} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 opts
               )

      assert %{status: "rejected"} =
               verdict =
               Content.get_publication_verdict(target_sha)

      assert [%{"path" => "notes/webhook-broken/en.md"}] =
               verdict.structured_errors["errors"]
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

  defp github_status_opts do
    [
      github_token: "token",
      github_status_client: GitHubStatusClient.Mock,
      github_status_owner: "zaneriley",
      github_status_repo: "personal-site-content"
    ]
  end
end
