defmodule PortfolioWeb.TypographyBenchControllerTest do
  use PortfolioWeb.ConnCase, async: true

  test "manifest inventories generated sizes and supported component roles", %{
    conn: conn
  } do
    body = conn |> get("/typography-bench/manifest") |> json_response(200)
    assert "3xs" in body["sizes"]
    assert "mono" in body["options"]["fonts"]
    assert body["metrics"] != %{}
  end

  test "specimens use the real component and preserve locale", %{conn: conn} do
    body =
      conn
      |> get("/typography-bench/specimen?font=mono&size=3xs&locale=ja")
      |> html_response(200)

    assert body =~ "optical-adjustment"
    assert body =~ "font-gt-flexa-mono"
    assert body =~ "text-3xs"
    assert body =~ ~s(lang="ja")
    assert body =~ "東京"
  end

  test "invalid query values cannot inject HTML or arbitrary CSS", %{conn: conn} do
    body =
      conn
      |> get("/typography-bench/specimen", %{
        font: "<script>bad</script>",
        fault: "bad"
      })
      |> html_response(200)

    refute body =~ "<script>bad</script>"
    assert body =~ ~s(data-fault="none")
  end

  test "controls and specimen are separate documents", %{conn: conn} do
    body = conn |> get("/typography-bench") |> html_response(200)
    assert body =~ "<iframe"
    refute body =~ "optical-adjustment"
  end
end
