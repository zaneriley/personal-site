defmodule PortfolioWeb.Plugs.CSPHeader do
  @moduledoc """
  Handles the construction and application of Content Security Policy headers.
  """
  import Plug.Conn

  @env Mix.env()
  @prod_env :prod

  def init(opts) do
    # Initialize any options here. For now, we'll just pass them through.
    opts
  end

  def call(conn, _opts) do
    config = get_csp_config()
    csp = build_csp(config)
    header_name = determine_header_name(config[:report_only])

    put_resp_header(conn, header_name, csp)
  end

  @spec put_csp_header(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def put_csp_header(conn, _opts) do
    config = get_csp_config()
    csp = build_csp(config)
    header_name = determine_header_name(config[:report_only])

    Plug.Conn.put_resp_header(conn, header_name, csp)
  end

  defp get_csp_config do
    Application.get_env(:portfolio, :csp, [])
  end

  defp build_csp(config) do
    base_url = construct_url(config, :base)
    ws_url = construct_url(config, :ws)
    {additional_hosts, additional_ws} = get_additional_urls(config[:port])

    [
      default_src: "'self' #{base_url} #{additional_hosts}",
      script_src: "'self' #{base_url} #{additional_hosts} 'unsafe-inline'",
      style_src: "'self' #{base_url} #{additional_hosts} 'unsafe-inline'",
      img_src: "'self' #{base_url} #{additional_hosts} data:",
      font_src: "'self' #{base_url} #{additional_hosts}",
      connect_src:
        "'self' #{base_url} #{additional_hosts} #{ws_url} #{additional_ws}",
      frame_src: frame_src(),
      object_src: "'none'",
      base_uri: "'self'",
      form_action: "'self'",
      frame_ancestors: "'none'"
    ]
    |> maybe_add_upgrade_insecure_requests()
    |> Enum.map_join("; ", fn {key, value} -> "#{key} #{value}" end)
  end

  defp construct_url(config, type) do
    scheme = config[:scheme] || "http"
    host = config[:host] || "localhost"
    port = config[:port] || "8000"

    url_scheme =
      case {type, scheme} do
        {:ws, "https"} -> "wss"
        {:ws, _} -> "ws"
        _ -> scheme
      end

    port_segment = if port in ["80", "443"], do: "", else: ":#{port}"
    "#{url_scheme}://#{host}#{port_segment}"
  end

  defp get_additional_urls(port) when @env == :dev do
    {
      "http://0.0.0.0:#{port} https://0.0.0.0:#{port}",
      "ws://0.0.0.0:* wss://0.0.0.0:*"
    }
  end

  defp get_additional_urls(_), do: {"", ""}

  defp frame_src when @env == :dev, do: "'self'"
  defp frame_src, do: "'none'"

  defp maybe_add_upgrade_insecure_requests(directives) when @env == @prod_env do
    [{"upgrade-insecure-requests", ""} | directives]
  end

  defp maybe_add_upgrade_insecure_requests(directives), do: directives

  defp determine_header_name(true), do: "content-security-policy-report-only"
  defp determine_header_name(_), do: "content-security-policy"
end
