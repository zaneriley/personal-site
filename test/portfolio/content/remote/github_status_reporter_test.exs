defmodule Portfolio.Content.Remote.GitHubStatusReporterTest do
  use Portfolio.DataCase, async: true

  import Mox
  import Portfolio.ContentFixtures

  alias Portfolio.Content.Publishing
  alias Portfolio.Content.Remote.GitHubStatusClient
  alias Portfolio.Content.Remote.GitHubStatusReporter

  setup :verify_on_exit!

  describe "report/2" do
    test "posts accepted content as a successful GitHub status" do
      content_sha = String.duplicate("a", 40)
      {:ok, generation} = Publishing.prepare_generation(content_sha)

      note_fixture(%{"url" => "github-status-note"},
        publication_generation_id: generation.id
      )

      assert {:ok, entry} =
               Publishing.record_publication_event(
                 "github-status-accepted",
                 content_sha,
                 :accepted,
                 generation_id: generation.id,
                 repository:
                   "https://github.com/zaneriley/personal-site-content.git"
               )

      expect(GitHubStatusClient.Mock, :create_status, fn
        "zaneriley", "personal-site-content", ^content_sha, payload, opts ->
          assert payload.state == "success"
          assert payload.context == "content/publication"
          assert payload.description == "Content accepted and live"
          assert payload.target_url =~ "/ops/content/publications/#{entry.id}"
          assert Keyword.fetch!(opts, :token) == "token"
          assert Keyword.fetch!(opts, :api_url) == "https://api.github.com"

          :ok
      end)

      assert :ok =
               GitHubStatusReporter.report(entry,
                 github_token: "token",
                 github_status_client: GitHubStatusClient.Mock
               )
    end

    test "posts rejected content as a failed GitHub status with a debug URL" do
      content_sha = String.duplicate("b", 40)

      assert {:ok, entry} =
               Publishing.record_publication_event(
                 "github-status-rejected",
                 content_sha,
                 :rejected,
                 reason: "Content promotion failed",
                 repository:
                   "git@github.com:zaneriley/personal-site-content.git",
                 structured_errors: %{
                   "errors" => [
                     %{
                       "path" => "notes/broken/en.md",
                       "reason" => "invalid frontmatter"
                     }
                   ]
                 }
               )

      expect(GitHubStatusClient.Mock, :create_status, fn
        "zaneriley", "personal-site-content", ^content_sha, payload, _opts ->
          assert payload.state == "failure"
          assert payload.context == "content/publication"
          assert payload.description == "Content promotion failed"
          assert payload.target_url =~ "/ops/content/publications/#{entry.id}"
          assert payload.target_url =~ "token="

          :ok
      end)

      assert :ok =
               GitHubStatusReporter.report(entry,
                 github_token: "token",
                 github_status_client: GitHubStatusClient.Mock
               )
    end

    test "does nothing when no GitHub token is configured" do
      content_sha = String.duplicate("c", 40)

      assert {:ok, entry} =
               Publishing.record_publication_event(
                 "github-status-disabled",
                 content_sha,
                 :ignored,
                 reason: "No relevant content changes"
               )

      assert :disabled =
               GitHubStatusReporter.report(entry,
                 github_status_client: GitHubStatusClient.Mock
               )
    end
  end
end
