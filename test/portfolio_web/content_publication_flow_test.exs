defmodule PortfolioWeb.ContentPublicationFlowTest do
  use PortfolioWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Portfolio.ContentRepoHelpers
  import Portfolio.GitHubWebhookHelpers

  alias Portfolio.Content
  alias Portfolio.Content.Publishing

  describe "content publication flow" do
    test "merged content delivery publishes good content and preserves last-good on bad content",
         %{conn: conn} do
      source_repo = tmp_dir!("publication-flow-source")
      clone_path = tmp_dir!("publication-flow-clone")

      on_exit(fn ->
        File.rm_rf!(source_repo)
        File.rm_rf!(clone_path)
      end)

      put_portfolio_env!(
        content_repo_url: source_repo,
        content_base_path: clone_path,
        github_token: nil
      )

      init_repo!(source_repo)

      content_path = "notes/publication-flow/en.md"
      note_url = "publication-flow"

      write_note!(
        source_repo,
        content_path,
        title: "Publication Flow",
        url: note_url,
        body: "First body from the content repo."
      )

      first_sha = commit!(source_repo, "publish first flow note")

      assert_delivery_accepted(conn, source_repo, first_sha,
        delivery_id: "publication-flow-first",
        changes: %{added: [content_path]}
      )

      assert %{live: ^first_sha, last_rejected_sha: nil} =
               Publishing.status()

      assert_note_body(note_url, "First body from the content repo.")

      write_note!(
        source_repo,
        content_path,
        title: "Publication Flow",
        url: note_url,
        body: "Updated body from the merged content change."
      )

      second_sha = commit!(source_repo, "publish updated flow note")

      assert_delivery_accepted(conn, source_repo, second_sha,
        delivery_id: "publication-flow-second",
        changes: %{modified: [content_path]}
      )

      assert %{live: ^second_sha, last_rejected_sha: nil} =
               Publishing.status()

      assert_note_body(note_url, "Updated body from the merged content change.")

      write_invalid_note!(source_repo, content_path)
      rejected_sha = commit!(source_repo, "publish invalid flow note")

      assert_delivery_received(conn, source_repo, rejected_sha,
        delivery_id: "publication-flow-rejected",
        changes: %{modified: [content_path]}
      )

      assert %{
               live: ^second_sha,
               last_rejected_sha: ^rejected_sha,
               last_rejected_reason: reason
             } = Publishing.status()

      assert reason =~ content_path
      assert reason =~ "invalid markdown format"

      assert %{status: "rejected"} =
               verdict =
               Content.get_publication_verdict(rejected_sha)

      assert [%{"path" => ^content_path}] = verdict.structured_errors["errors"]

      assert_publication_debug_page(verdict, rejected_sha, content_path, reason)
      assert_note_body(note_url, "Updated body from the merged content change.")
    end
  end

  defp assert_delivery_accepted(conn, repo_url, sha, opts) do
    assert_delivery_received(conn, repo_url, sha, opts)
    assert %{status: "accepted"} = Content.get_publication_verdict(sha)
  end

  defp assert_delivery_received(conn, repo_url, sha, opts) do
    payload =
      github_push_payload(
        after: sha,
        repository_url: repo_url,
        changes: Keyword.fetch!(opts, :changes)
      )

    {conn, encoded_payload} =
      signed_github_webhook_conn(conn, payload,
        delivery_id: Keyword.fetch!(opts, :delivery_id)
      )

    assert get_req_header(conn, "x-github-event") == ["push"]

    assert get_req_header(conn, "x-hub-signature-256") == [
             github_webhook_signature(encoded_payload)
           ]

    conn = post(conn, github_webhook_path(), encoded_payload)
    assert response(conn, :ok) == "OK"
    Portfolio.DataCase.clear_cache()
  end

  defp assert_note_body(note_url, expected_text) do
    {:ok, _view, html} = live(build_conn(), ~p"/en/note/#{note_url}")

    assert html =~ "Publication Flow"
    assert html =~ expected_text
    refute html =~ "We ran into an issue loading this note"
  end

  defp assert_publication_debug_page(verdict, rejected_sha, path, reason) do
    url = PortfolioWeb.ContentPublicationDebugLink.signed_url(verdict)
    response = build_conn() |> get(url_path(url)) |> html_response(200)

    assert response =~ rejected_sha
    assert response =~ path
    assert String.replace(response, "&#39;", "'") =~ reason
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
