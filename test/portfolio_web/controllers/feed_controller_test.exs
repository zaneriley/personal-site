defmodule PortfolioWeb.FeedControllerTest do
  use PortfolioWeb.ConnCase

  import Portfolio.ContentFixtures

  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Repo

  describe "GET /:locale/feeds/:feed.xml" do
    test "serves the main feed as Atom with the curated entries", %{conn: conn} do
      note = note_fixture(%{"main_feed" => true, "title" => "Promoted note"})
      _quiet = note_fixture(%{"title" => "Quiet note"})
      cs = case_study_fixture(%{"title" => "A case study"})

      conn = get(conn, "/en/feeds/main.xml")

      assert response_content_type(conn, :atom) =~ "application/atom+xml"
      body = response(conn, 200)
      assert body =~ ~s(<feed xmlns="http://www.w3.org/2005/Atom")
      assert body =~ ~s(xml:lang="en")
      assert body =~ "Promoted note"
      assert body =~ "A case study"
      refute body =~ "Quiet note"
      assert body =~ note.id
      assert body =~ cs.id
    end

    test "a slug rename never duplicates the entry for subscribers", %{
      conn: conn
    } do
      note = note_fixture(%{"main_feed" => true, "url" => "original-slug"})

      body_before = conn |> get("/en/feeds/main.xml") |> response(200)

      [id_before] =
        Regex.run(~r{<id>([^<]+)</id>}, entry_block(body_before),
          capture: :all_but_first
        )

      note
      |> Note.changeset(%{
        "url" => "renamed-slug",
        "aliases" => ["original-slug"]
      })
      |> Repo.update!()

      body_after = build_conn() |> get("/en/feeds/main.xml") |> response(200)

      [id_after] =
        Regex.run(~r{<id>([^<]+)</id>}, entry_block(body_after),
          capture: :all_but_first
        )

      assert id_before == id_after
      assert id_after == "tag:zaneriley.com,2026:note/#{note.id}/en"
      assert body_after =~ "renamed-slug"
    end

    test "all URLs are absolute, including inside the content HTML", %{
      conn: conn
    } do
      note_fixture(%{
        "main_feed" => true,
        "content" => "See [the other note](/en/note/other-note) for context."
      })

      body = conn |> get("/en/feeds/main.xml") |> response(200)

      # the alternate link is absolute
      assert [link] =
               Regex.run(
                 ~r{<link rel="alternate"[^>]*href="([^"]+)"},
                 entry_block(body),
                 capture: :all_but_first
               )

      assert String.starts_with?(link, "http")

      # the relative link inside content was rewritten before escaping
      assert body =~ "/en/note/other-note"
      refute body =~ ~s(href=&quot;/en/note/other-note)
    end

    test "dates are RFC 3339 and updated never precedes published", %{
      conn: conn
    } do
      note_fixture(%{"main_feed" => true})

      body = conn |> get("/en/feeds/main.xml") |> response(200)
      entry = entry_block(body)

      [published] =
        Regex.run(~r{<published>([^<]+)</published>}, entry,
          capture: :all_but_first
        )

      [updated] =
        Regex.run(~r{<updated>([^<]+)</updated>}, entry,
          capture: :all_but_first
        )

      assert {:ok, pub, 0} = DateTime.from_iso8601(published)
      assert {:ok, upd, 0} = DateTime.from_iso8601(updated)
      assert DateTime.compare(upd, pub) in [:gt, :eq]
    end

    test "a code block in a case study degrades to readable code, never broken markup",
         %{
           conn: conn
         } do
      note_fixture(%{
        "main_feed" => true,
        "content" =>
          "Some prose.\n\n```elixir\ndefmodule Foo do\n  :ok\nend\n```\n"
      })

      body = conn |> get("/en/feeds/main.xml") |> response(200)

      # the classified markup ships XML-escaped inside content type="html" —
      # readers unescape it back into spans; the source tokens are intact
      # (split across token spans, hence per-token assertions)
      assert body =~ "tok-keyword"
      assert body =~ "defmodule"
      assert body =~ ":ok"
      refute body =~ ~r{<content type="html"[^>]*><[a-z]}
    end

    test "the ja feed carries ja renderings and only translated entries", %{
      conn: conn
    } do
      translated = note_fixture(%{}, skip_translations: true)
      translation_fixture(translated, "ja", %{"title" => "翻訳されたノート"})
      untranslated = note_fixture(%{}, skip_translations: true)

      body = conn |> get("/ja/feeds/notes.xml") |> response(200)

      assert body =~ ~s(xml:lang="ja")
      assert body =~ "翻訳されたノート"
      refute body =~ untranslated.id
    end

    test "an unknown feed or locale is a 404, not an empty feed", %{conn: conn} do
      assert conn |> get("/en/feeds/secrets.xml") |> response(404)
      assert build_conn() |> get("/xx/feeds/main.xml") |> response(404)
    end
  end

  describe "conditional requests" do
    test "the ETag derives from the rendered document and a match is a 304", %{
      conn: conn
    } do
      note_fixture(%{"main_feed" => true})

      first = get(conn, "/en/feeds/main.xml")
      assert [etag] = get_resp_header(first, "etag")

      not_modified =
        build_conn()
        |> put_req_header("if-none-match", etag)
        |> get("/en/feeds/main.xml")

      assert not_modified.status == 304
      assert not_modified.resp_body == ""

      # new content invalidates the validator
      note_fixture(%{"main_feed" => true, "title" => "Newer entry"})

      changed =
        build_conn()
        |> put_req_header("if-none-match", etag)
        |> get("/en/feeds/main.xml")

      assert changed.status == 200
      assert [new_etag] = get_resp_header(changed, "etag")
      refute new_etag == etag
    end
  end

  describe "GET /feed.xml" do
    test "the convention alias 301s to the en main feed", %{conn: conn} do
      conn = get(conn, "/feed.xml")

      assert conn.status == 301
      assert get_resp_header(conn, "location") == ["/en/feeds/main.xml"]
    end
  end

  describe "GET /:locale/feeds — the discovery page" do
    test "lists every feed with its volume description and Atom link", %{
      conn: conn
    } do
      html = conn |> get("/en/feeds") |> html_response(200)

      for feed <- [:main, :case_studies, :notes, :everything] do
        assert html =~ PortfolioWeb.Feeds.title(feed)
        assert html =~ PortfolioWeb.Feeds.path(feed, "en")
      end

      assert html =~ "firehose"
    end
  end

  describe "autodiscovery" do
    test "every page advertises the locale's main feed", %{conn: conn} do
      html = conn |> get("/en") |> html_response(200)

      assert html =~ ~s(type="application/atom+xml")
      assert html =~ ~s(href="/en/feeds/main.xml")
    end

    test "section index pages also advertise their section feed", %{conn: conn} do
      html = conn |> get("/en/notes") |> html_response(200)

      assert html =~ ~s(href="/en/feeds/main.xml")
      assert html =~ ~s(href="/en/feeds/notes.xml")
    end
  end

  # The first <entry> block — enough scope for id/link/date assertions.
  defp entry_block(body) do
    [block] = Regex.run(~r{<entry>.*?</entry>}s, body)
    block
  end
end
