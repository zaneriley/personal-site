defmodule PortfolioWeb.TypographyBenchController do
  @moduledoc "Development-only typography specimens and measurement controls."
  use PortfolioWeb, :controller

  alias PortfolioWeb.Components.TypographyHelpers
  alias PortfolioWeb.TypographyBenchHTML

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, "assets/typography-bench/index.html")
  end

  @spec script(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def script(conn, _params) do
    conn
    |> put_resp_content_type("text/javascript")
    |> send_file(200, "assets/typography-bench/bench.js")
  end

  @spec measure_script(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def measure_script(conn, _params) do
    conn
    |> put_resp_content_type("text/javascript")
    |> send_file(200, "assets/typography-bench/measure.js")
  end

  @spec manifest(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def manifest(conn, _params) do
    css = File.read!("assets/css/_type-tokens.generated.css")

    sizes =
      Regex.scan(~r/--latin-fs-([\w]+):/, css, capture: :all_but_first)
      |> List.flatten()

    metrics = File.read!("assets/tailwind/font-metrics.json") |> Jason.decode!()
    audit = font_audit()

    json(conn, %{
      options: TypographyHelpers.options(),
      sizes: sizes,
      weights: ["regular", "bold"],
      locales: ["en", "ja"],
      specimens: ["caps", "descenders", "punctuation", "mixed", "paragraph"],
      stress_cases:
        Enum.map(TypographyBenchHTML.stress_cases(), &Map.drop(&1, [:text])),
      metrics: metrics,
      artifacts: font_files(audit, "generated"),
      sources: font_files(audit, "source"),
      font_css: File.read!("assets/css/_fontface.generated.css"),
      font_audit: audit,
      limitations: [
        "Source/artifact raster parity is not measured yet",
        "Canvas ink is a single-run diagnostic, not DOM ink",
        "Optical approval is not automated"
      ]
    })
  end

  @spec specimen(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def specimen(conn, params) do
    options = TypographyHelpers.options()

    assigns = %{
      __changed__: nil,
      font: choose(params, "font", options.fonts, "mono"),
      size: choose(params, "size", options.sizes, "3xs"),
      weight: choose(params, "weight", ~w(regular bold), "regular"),
      locale: choose(params, "locale", ~w(en ja), "en"),
      sample:
        choose(
          params,
          "sample",
          ~w(caps descenders punctuation mixed paragraph) ++
            Enum.map(TypographyBenchHTML.stress_cases(), & &1.id),
          "caps"
        ),
      mode: choose(params, "mode", ~w(single stack weather article), "stack"),
      theme: choose(params, "theme", ~w(dark light), "dark"),
      fault: choose(params, "fault", ~w(none margin font), "none")
    }

    Gettext.put_locale(PortfolioWeb.Gettext, assigns.locale)

    conn
    |> put_root_layout(false)
    |> put_layout(false)
    |> put_view(TypographyBenchHTML)
    |> render(:specimen, assigns)
  end

  defp choose(params, key, values, default) do
    value = Map.get(params, key, default)
    if value in values, do: value, else: default
  end

  # File identities come from the audit script's report, so the bench never
  # reads font files itself. Before the audit runs, report that instead.
  defp font_files(%{"records" => records}, stage) do
    for %{"stage" => ^stage} = record <- records,
        do: Map.take(record, ["file", "bytes", "sha256"])
  end

  defp font_files(not_run, _stage), do: not_run

  defp font_audit do
    case File.read(".tmp/typography-bench/font-audit.json") do
      {:ok, data} ->
        Jason.decode!(data)

      {:error, :enoent} ->
        %{
          status: "not run",
          command: "./run _dc js node typography-bench/audit-fonts.mjs"
        }
    end
  end
end
