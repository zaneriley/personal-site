defmodule PortfolioWeb.Plugs.CSPHeader do
  @moduledoc """
  Handles the construction and application of Content Security Policy headers.
  Provides dynamic CSP generation based on runtime configuration and environment.
  """
  import Plug.Conn
  require Logger

  @type csp_config :: %{
          scheme: String.t(),
          host: String.t(),
          port: String.t(),
          additional_hosts: list(String.t()),
          report_only: boolean()
        }
  @type report_only :: boolean()
  @env Application.compile_env(:portfolio, :environment)
  @env_module if @env == :dev,
                do: PortfolioWeb.Plugs.CSPHeader.Dev,
                else: PortfolioWeb.Plugs.CSPHeader.Prod
  @report_only Application.compile_env(:portfolio, [:csp, :report_only], false)
  @default_scheme "https"
  @default_port "443"
  @default_host "localhost"

  @spec generate_csp_for_testing(map()) :: String.t()
  def generate_csp_for_testing(config) do
    build_csp(config)
  end

  @spec init(keyword()) :: keyword()
  def init(opts) do
    Logger.debug(
      "CSPHeader init - Environment: #{@env}, Module: #{@env_module}"
    )

    opts
  end

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    conn
    |> get_csp_config()
    |> build_csp()
    |> apply_csp_header(conn)
  end

  defp apply_csp_header(csp, conn) do
    header_name =
      if @report_only,
        do: "content-security-policy-report-only",
        else: "content-security-policy"

    put_resp_header(conn, header_name, csp)
  end

  @spec get_csp_config(Plug.Conn.t()) :: csp_config()
  defp get_csp_config(conn) do
    %{
      scheme: System.get_env("URL_SCHEME", @default_scheme),
      host: get_host(conn),
      port: System.get_env("URL_PORT", @default_port),
      additional_hosts: parse_additional_hosts(),
      report_only: @report_only
    }
  end

  defp get_host(conn) do
    conn.host ||
      Application.get_env(:portfolio, PortfolioWeb.Endpoint)[:url][:host]
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
    ws_url = construct_url(config, :ws)
    all_hosts = get_all_hosts(config)

    [
      default_src: "'self' #{all_hosts}",
      script_src: "'self' #{all_hosts} 'unsafe-inline'",
      style_src: "'self' #{all_hosts} 'unsafe-inline'",
      img_src: "'self' #{all_hosts} data:",
      font_src: "'self' #{all_hosts}",
      connect_src: "'self' #{all_hosts} #{ws_url}",
      frame_src: @env_module.frame_src(),
      object_src: "'none'",
      base_uri: "'self'",
      form_action: "'self'",
      frame_ancestors: "'none'"
    ]
    |> @env_module.maybe_add_upgrade_insecure_requests()
    |> Enum.map_join("; ", fn {key, value} ->
      "#{key |> to_string() |> String.replace("_", "-")} #{value}"
    end)
  end

  @spec construct_url(csp_config, :base | :ws) :: String.t()
  defp construct_url(config, type) do
    scheme =
      if type == :ws and config.scheme == "https",
        do: "wss",
        else: config.scheme

    port = if config.port in ["80", "443"], do: "", else: ":#{config.port}"
    "#{scheme}://#{config.host}#{port}"
  end

  @spec get_all_hosts(csp_config) :: String.t()
  defp get_all_hosts(config) do
    [config.host, "localhost", "0.0.0.0" | config.additional_hosts]
    |> Enum.map_join(" ", &"#{config.scheme}://#{&1}:#{config.port}")
  end
end
