defmodule PortfolioWeb.ContentPublicationControllerTest do
  use PortfolioWeb.ConnCase, async: true

  alias Portfolio.Content.Publishing
  alias PortfolioWeb.ContentPublicationDebugLink

  describe "GET /ops/content/publications/:id" do
    test "signed debug URLs use the configured site origin" do
      content_sha = String.duplicate("a", 40)

      assert {:ok, entry} =
               Publishing.record_publication_event(
                 "debug-view-signed-url",
                 content_sha,
                 :ignored,
                 reason: "No relevant content changes"
               )

      assert ContentPublicationDebugLink.signed_url(entry) =~
               ~r/\A#{Regex.escape(PortfolioWeb.Endpoint.url())}\/ops\/content\/publications\//
    end

    test "renders a signed private publication debug view", %{conn: conn} do
      content_sha = String.duplicate("d", 40)

      assert {:ok, entry} =
               Publishing.record_publication_event(
                 "debug-view-rejected",
                 content_sha,
                 :rejected,
                 reason: "Content promotion failed",
                 repository:
                   "https://github.com/zaneriley/personal-site-content.git",
                 ref: "refs/heads/main",
                 structured_errors: %{
                   "errors" => [
                     %{
                       "path" => "notes/broken/en.md",
                       "reason" => "invalid frontmatter"
                     }
                   ]
                 }
               )

      path = ContentPublicationDebugLink.signed_url(entry) |> url_path()
      conn = get(conn, path)

      response = html_response(conn, 200)

      assert get_resp_header(conn, "x-robots-tag") == [
               "noindex, nofollow, noarchive"
             ]

      assert response =~ "Content promotion failed"
      assert response =~ content_sha
      assert response =~ "debug-view-rejected"
      assert response =~ "notes/broken/en.md"
      assert response =~ "invalid frontmatter"
    end

    test "rejects unsigned requests", %{conn: conn} do
      content_sha = String.duplicate("e", 40)

      assert {:ok, entry} =
               Publishing.record_publication_event(
                 "debug-view-unsigned",
                 content_sha,
                 :ignored,
                 reason: "No relevant content changes"
               )

      conn = get(conn, ~p"/ops/content/publications/#{entry.id}")

      assert response(conn, 404) == "not found"
    end

    test "rejects tokens signed for a different publication", %{conn: conn} do
      first_sha = String.duplicate("f", 40)
      second_sha = String.duplicate("1", 40)

      assert {:ok, first_entry} =
               Publishing.record_publication_event(
                 "debug-view-first-entry",
                 first_sha,
                 :ignored,
                 reason: "No relevant content changes"
               )

      assert {:ok, second_entry} =
               Publishing.record_publication_event(
                 "debug-view-second-entry",
                 second_sha,
                 :ignored,
                 reason: "No relevant content changes"
               )

      %URI{query: query} =
        first_entry
        |> ContentPublicationDebugLink.signed_url()
        |> URI.parse()

      %{"token" => token} = URI.decode_query(query)

      conn =
        get(
          conn,
          ~p"/ops/content/publications/#{second_entry.id}?#{%{token: token}}"
        )

      assert response(conn, 404) == "not found"
    end

    test "renders ignored publications with no structured errors", %{conn: conn} do
      content_sha = String.duplicate("2", 40)

      assert {:ok, entry} =
               Publishing.record_publication_event(
                 "debug-view-ignored",
                 content_sha,
                 :ignored,
                 reason: "No relevant content changes"
               )

      path = ContentPublicationDebugLink.signed_url(entry) |> url_path()
      conn = get(conn, path)

      response = html_response(conn, 200)

      assert response =~ "No relevant content changes"
      assert response =~ "No structured path errors recorded."
    end
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
