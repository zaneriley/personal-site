defmodule PortfolioWeb.ReadinessControllerTest do
  @moduledoc false

  use PortfolioWeb.ConnCase, async: true

  import Portfolio.ContentFixtures

  alias Portfolio.Content.Publishing

  describe "GET /readyz" do
    test "returns unavailable when no live content has been accepted", %{
      conn: conn
    } do
      conn = get(conn, ~p"/readyz")

      assert text_response(conn, 503) == "content not ready"
    end

    test "returns ok after the database responds and content is live", %{
      conn: conn
    } do
      content_sha = String.duplicate("a", 40)
      {:ok, generation} = Publishing.prepare_generation(content_sha)
      note_fixture(%{}, publication_generation_id: generation.id)

      assert {:ok, _entry} =
               Publishing.record_publication_event(
                 "readiness-delivery",
                 content_sha,
                 :accepted,
                 generation_id: generation.id
               )

      conn = get(conn, ~p"/readyz")

      assert text_response(conn, 200) == "ok"
    end
  end
end
