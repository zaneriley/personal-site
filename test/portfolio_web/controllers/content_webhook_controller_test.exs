defmodule PortfolioWeb.ContentWebhookControllerTest do
  use PortfolioWeb.ConnCase, async: false

  @capture_owned_logs System.get_env("PORTFOLIO_TEST_LOG_LEVEL") != "debug"

  import Mox
  import Portfolio.ContentRepoHelpers
  import Portfolio.GitHubWebhookHelpers

  alias Portfolio.Content
  alias Portfolio.Content.Remote.GitHubStatusClient
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Repo

  setup :verify_on_exit!

  describe "POST /api/v1/content/push" do
    @tag capture_log: @capture_owned_logs
    test "reports rejected content with a signed debug status URL", %{
      conn: conn
    } do
      source_repo = tmp_dir!("webhook-endpoint-rejected-source")
      clone_path = tmp_dir!("webhook-endpoint-rejected-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)

      write_file!(
        source_repo,
        "notes/webhook-broken/en.md",
        """
        ---
        url: "webhook-broken"
        introduction: "Intro"
        published_at: "2024-07-27T14:30:00Z"
        is_draft: false
        ---

        # Missing Title
        """
      )

      target_sha = commit!(source_repo, "publish broken webhook note")
      delivery_id = "webhook-delivery-endpoint-rejected"
      test_pid = self()

      put_portfolio_env!(
        content_repo_url: source_repo,
        content_base_path: clone_path,
        github_token: "token",
        github_status_client: GitHubStatusClient.Mock,
        github_status_owner: "zaneriley",
        github_status_repo: "personal-site-content"
      )

      payload =
        github_push_payload(
          after: target_sha,
          repository_url: source_repo,
          changes: %{added: ["notes/webhook-broken/en.md"]}
        )

      expect(GitHubStatusClient.Mock, :create_status, fn
        "zaneriley", "personal-site-content", ^target_sha, payload, _opts ->
          assert payload.state == "failure"
          assert payload.description =~ "notes/webhook-broken/en.md:"
          assert payload.description =~ "title: can't be blank"
          assert payload.target_url =~ "/ops/content/publications/"
          assert payload.target_url =~ "token="

          send(test_pid, {:github_status_target_url, payload.target_url})

          :ok
      end)

      {conn, encoded_payload} =
        signed_github_webhook_conn(conn, payload, delivery_id: delivery_id)

      assert get_req_header(conn, "content-type") == ["application/json"]
      assert get_req_header(conn, "x-github-event") == ["push"]
      assert get_req_header(conn, "x-github-delivery") == [delivery_id]

      assert get_req_header(conn, "x-hub-signature-256") == [
               github_webhook_signature(encoded_payload)
             ]

      conn = post(conn, github_webhook_path(), encoded_payload)

      assert response(conn, :ok) == "OK"
      assert_receive {:github_status_target_url, target_url}

      debug_conn = get(build_conn(), url_path(target_url))
      response = html_response(debug_conn, 200)

      assert response =~ "notes/webhook-broken/en.md:"
      assert response =~ target_sha
      assert response =~ delivery_id
      assert response =~ "notes/webhook-broken/en.md"
      assert response =~ "title: can&#39;t be blank"

      assert %{status: "rejected"} =
               verdict =
               Content.get_publication_verdict(target_sha)

      assert [%{"reason" => reason}] = verdict.structured_errors["errors"]
      assert reason == "title: can't be blank"
      assert String.replace(response, "&#39;", "'") =~ reason
    end
  end

  describe "handle_webhook/3" do
    test "triggers update for push event with relevant changes", %{conn: conn} do
      source_repo = tmp_dir!("webhook-source")
      clone_path = tmp_dir!("webhook-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_note!(source_repo, "notes/webhook-note/en.md", url: "webhook-note")
      target_sha = commit!(source_repo, "publish webhook note")

      payload =
        github_push_payload(
          after: target_sha,
          repository_url: source_repo,
          changes: %{added: ["notes/webhook-note/en.md"]}
        )

      {conn, _encoded_payload} =
        signed_github_webhook_conn(conn, payload,
          delivery_id: "webhook-delivery-relevant"
        )

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
          content_base_path: clone_path
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
      target_sha = String.duplicate("a", 40)

      payload =
        github_push_payload(
          after: target_sha,
          repository_url: "https://example.test/content.git",
          changes: %{
            added: ["irrelevant-file.txt"],
            modified: [".gitignore"]
          }
        )

      {conn, _encoded_payload} =
        signed_github_webhook_conn(conn, payload,
          delivery_id: "webhook-delivery-ignored"
        )

      expect(GitHubStatusClient.Mock, :create_status, fn
        "zaneriley", "personal-site-content", sha, payload, _opts ->
          assert sha == target_sha
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
                   content_repo_url: "https://example.test/content.git"
                 ] ++ github_status_opts()
               )

      assert %{
               status: "ignored",
               reason: "No relevant content changes"
             } = Content.get_publication_verdict(target_sha)
    end

    @tag capture_log: @capture_owned_logs
    test "reports a failed status for rejected content pushes", %{conn: conn} do
      source_repo = tmp_dir!("webhook-rejected-source")
      clone_path = tmp_dir!("webhook-rejected-clone")
      on_exit(fn -> File.rm_rf!(source_repo) end)
      on_exit(fn -> File.rm_rf!(clone_path) end)

      init_repo!(source_repo)
      write_invalid_note!(source_repo, "notes/webhook-broken/en.md")
      target_sha = commit!(source_repo, "publish broken webhook note")

      payload =
        github_push_payload(
          after: target_sha,
          repository_url: source_repo,
          changes: %{added: ["notes/webhook-broken/en.md"]}
        )

      {conn, _encoded_payload} =
        signed_github_webhook_conn(conn, payload,
          delivery_id: "webhook-delivery-rejected"
        )

      expect(GitHubStatusClient.Mock, :create_status, fn
        "zaneriley", "personal-site-content", ^target_sha, payload, _opts ->
          assert payload.state == "failure"
          assert payload.description =~ "notes/webhook-broken/en.md:"

          assert payload.description =~
                   "invalid markdown format: expected YAML frontmatter"

          assert payload.target_url =~ "/ops/content/publications/"

          :ok
      end)

      opts =
        [
          content_repo_url: source_repo,
          content_base_path: clone_path
        ] ++ github_status_opts()

      assert {:error, response} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 opts
               )

      assert response =~ ~s(Update failed: "notes/webhook-broken/en.md:)
      assert response =~ "invalid markdown format: expected YAML frontmatter"

      assert %{status: "rejected", reason: reason} =
               verdict =
               Content.get_publication_verdict(target_sha)

      assert reason =~ "notes/webhook-broken/en.md:"

      assert [%{"path" => "notes/webhook-broken/en.md"}] =
               verdict.structured_errors["errors"]
    end

    @tag capture_log: @capture_owned_logs
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

    @tag capture_log: @capture_owned_logs
    test "rejects push-shaped payloads without a push event header", %{
      conn: conn
    } do
      payload =
        github_push_payload(
          after: String.duplicate("a", 40),
          repository_url: "https://example.test/content.git",
          changes: %{added: ["notes/new/en.md"]}
        )

      {conn, _encoded_payload} =
        signed_github_webhook_conn(conn, payload,
          delivery_id: "webhook-delivery-wrong-event",
          event: "issues"
        )

      assert {:error, "Unexpected GitHub event: issues"} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 content_repo_url: "https://example.test/content.git"
               )
    end

    @tag capture_log: @capture_owned_logs
    test "rejects invalid payload", %{conn: conn} do
      invalid_payload = %{"invalid" => "data"}

      assert {:error, "Invalid or unsupported event type"} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 invalid_payload,
                 content_repo_url: "https://example.test/content.git"
               )
    end

    @tag capture_log: @capture_owned_logs
    test "rejects pushes from unexpected refs", %{conn: conn} do
      payload =
        github_push_payload(
          after: String.duplicate("a", 40),
          ref: "refs/heads/draft",
          repository_url: "https://example.test/content.git",
          changes: %{added: ["notes/new/en.md"]}
        )

      {conn, _encoded_payload} =
        signed_github_webhook_conn(conn, payload,
          delivery_id: "webhook-delivery-unexpected-ref"
        )

      assert {:error, "Unexpected ref: refs/heads/draft"} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 content_repo_url: "https://example.test/content.git"
               )
    end

    @tag capture_log: @capture_owned_logs
    test "rejects pushes from unexpected repositories", %{conn: conn} do
      payload =
        github_push_payload(
          after: String.duplicate("a", 40),
          repository_url: "https://example.test/other.git",
          changes: %{added: ["notes/new/en.md"]}
        )

      {conn, _encoded_payload} =
        signed_github_webhook_conn(conn, payload,
          delivery_id: "webhook-delivery-unexpected-repo"
        )

      assert {:error, "Unexpected repository"} =
               PortfolioWeb.ContentWebhookController.handle_webhook(
                 conn,
                 payload,
                 content_repo_url: "https://example.test/content.git"
               )
    end

    @tag capture_log: @capture_owned_logs
    test "rejects non-hex after shas", %{conn: conn} do
      payload =
        github_push_payload(
          after: String.duplicate("z", 40),
          repository_url: "https://example.test/content.git",
          changes: %{added: ["notes/new/en.md"]}
        )

      {conn, _encoded_payload} =
        signed_github_webhook_conn(conn, payload,
          delivery_id: "webhook-delivery-invalid-sha"
        )

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

  defp put_portfolio_env!(updates) do
    missing = make_ref()

    previous_values =
      Enum.map(updates, fn {key, _value} ->
        {key, Application.get_env(:portfolio, key, missing)}
      end)

    on_exit(fn ->
      Enum.each(previous_values, fn
        {key, ^missing} -> Application.delete_env(:portfolio, key)
        {key, value} -> Application.put_env(:portfolio, key, value)
      end)
    end)

    Enum.each(updates, fn {key, value} ->
      Application.put_env(:portfolio, key, value)
    end)
  end

  defp url_path(url) do
    %URI{path: path, query: query} = URI.parse(url)

    if query do
      "#{path}?#{query}"
    else
      path
    end
  end
end
