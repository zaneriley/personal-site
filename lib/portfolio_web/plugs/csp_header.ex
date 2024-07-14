defmodule PortfolioWeb.Plugs.CSPHeader do
  @moduledoc """
  Handles the construction and application of Content Security Policy headers.
  Provides dynamic CSP generation based on runtime configuration and environment.
  """
  import Plug.Conn

  @type csp_config :: %{
          scheme: String.t(),
          host: String.t(),
          port: String.t(),
          additional_hosts: list(String.t()),
          report_only: boolean()
        }

  @env Application.compile_env(:portfolio, :environment)

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    config = get_csp_config(conn)
    csp = build_csp(config)
    header_name = determine_header_name(config.report_only)

    put_resp_header(conn, header_name, csp)
  end

  @spec get_csp_config(Plug.Conn.t()) :: csp_config
  defp get_csp_config(conn) do
    # Detect the actual host being used
    actual_host =
      conn.host ||
        Application.get_env(:portfolio, PortfolioWeb.Endpoint)[:url][:host]

    %{
      scheme: System.get_env("URL_SCHEME", "http"),
      host: System.get_env("URL_HOST", actual_host),
      port: System.get_env("URL_PORT", "8000"),
      additional_hosts: parse_additional_hosts(),
      report_only: System.get_env("CSP_REPORT_ONLY", "false") == "true"
    }
  end

  @spec parse_additional_hosts() :: list(String.t())
  defp parse_additional_hosts do
    (System.get_env("CSP_ADDITIONAL_HOSTS", "") <> ",localhost,0.0.0.0")
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.uniq()
  end

  @spec build_csp(csp_config) :: String.t()
  defp build_csp(config) do
    base_url = construct_url(config, :base)
    ws_url = construct_url(config, :ws)
    all_hosts = get_all_hosts(config)

    [
      default_src: "'self' #{all_hosts}",
      script_src: "'self' #{all_hosts} 'unsafe-inline'",
      style_src: "'self' #{all_hosts} 'unsafe-inline'",
      img_src: "'self' #{all_hosts} data:",
      font_src: "'self' #{all_hosts}",
      connect_src: "'self' #{all_hosts} #{ws_url}",
      frame_src: frame_src(),
      object_src: "'none'",
      base_uri: "'self'",
      form_action: "'self'",
      frame_ancestors: "'none'"
    ]
    |> maybe_add_upgrade_insecure_requests()
    |> Enum.map_join("; ", fn {key, value} ->
      "#{key |> to_string() |> String.replace("_", "-")} #{value}"
    end)
  end

  @spec construct_url(csp_config, :base | :ws) :: String.t()
  defp construct_url(config, type) do
    url_scheme =
      if type == :ws and config.scheme == "https",
        do: "wss",
        else: config.scheme

    port_segment =
      if config.port in ["80", "443"], do: "", else: ":#{config.port}"

    "#{url_scheme}://#{config.host}#{port_segment}"
  end

  @spec get_all_hosts(csp_config) :: String.t()
  defp get_all_hosts(config) do
    base_hosts =
      [config.host, "localhost", "0.0.0.0"] ++ config.additional_hosts

    base_urls = Enum.map(base_hosts, &"#{config.scheme}://#{&1}:#{config.port}")
    Enum.join(base_urls, " ")
  end

  @dialyzer {:nowarn_function, frame_src: 0}
  @spec frame_src() :: String.t()
  defp frame_src when @env == :dev, do: "'self'"
  defp frame_src, do: "'none'"

  @dialyzer {:nowarn_function, maybe_add_upgrade_insecure_requests: 1}
  @spec maybe_add_upgrade_insecure_requests(keyword()) :: keyword()
  defp maybe_add_upgrade_insecure_requests(directives) when @env == :prod do
    [{"upgrade-insecure-requests", ""} | directives]
  end

  defp maybe_add_upgrade_insecure_requests(directives), do: directives

  @spec determine_header_name(boolean()) :: String.t()
  defp determine_header_name(true), do: "content-security-policy-report-only"
  defp determine_header_name(_), do: "content-security-policy"
end
