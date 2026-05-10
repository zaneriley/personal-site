defmodule PortfolioWeb.ContentPublicationControllerTest do
  use PortfolioWeb.ConnCase, async: true

  alias Portfolio.Content.Publishing
  alias PortfolioWeb.ContentPublicationDebugLink

  describe "GET /ops/content/publications/:id" do
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
