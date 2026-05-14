defmodule PortfolioWeb.Plugs.CSPHeader do
  @moduledoc """
  Emits a Content-Security-Policy (or -Report-Only) header derived from
  the current request. `'self'`-class directives use `conn.scheme`,
  `conn.host`, `conn.port` — never env vars — so previews on any reachable
  origin Just Work.

  Cross-origin allowlist is sourced from `CSP_ADDITIONAL_HOSTS` (comma list,
  default empty). `'unsafe-inline'` in `script-src` / `style-src` is retained
  pending a separate hardening slice.
  """
  @behaviour Plug

  import Plug.Conn

  @type origin :: %{
          required(:scheme) => String.t(),
          required(:host) => String.t(),
          required(:port) => pos_integer()
        }

  @header_name %{
    true => "content-security-policy-report-only",
    false => "content-security-policy"
  }

  @impl true
  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @impl true
  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    csp = build_csp(origin_from_conn(conn), additional_hosts(), env_module())
    put_resp_header(conn, Map.fetch!(@header_name, report_only?()), csp)
  end

  @spec generate_csp_for_testing(origin(), [String.t()], module()) :: String.t()
  def generate_csp_for_testing(
        origin,
        additional \\ [],
        env_mod \\ __MODULE__.Prod
      ) do
    build_csp(origin, additional, env_mod)
  end

  @spec origin_from_conn(Plug.Conn.t()) :: origin()
  defp origin_from_conn(%Plug.Conn{scheme: scheme, host: host, port: port}) do
    %{scheme: Atom.to_string(scheme), host: host, port: port}
  end

  @spec build_csp(origin(), [String.t()], module()) :: String.t()
  defp build_csp(origin, additional, env_mod) do
    self_origin = format_origin(origin)
    ws_origin = format_origin(%{origin | scheme: ws_scheme(origin.scheme)})
    extras = Enum.map_join(additional, " ", &"#{origin.scheme}://#{&1}")
    hosts = String.trim("#{self_origin} #{extras}")

    [
      default_src: "'self' #{hosts}",
      script_src: "'self' #{hosts} 'unsafe-inline'",
      style_src: "'self' #{hosts} 'unsafe-inline'",
      img_src: "'self' #{hosts} data:",
      font_src: "'self' #{hosts}",
      connect_src: "'self' #{hosts} #{ws_origin}",
      frame_src: env_mod.frame_src(),
      object_src: "'none'",
      base_uri: "'self'",
      form_action: "'self'",
      frame_ancestors: "'none'"
    ]
    |> env_mod.maybe_add_upgrade_insecure_requests()
    |> Enum.map_join("; ", fn {key, value} ->
      "#{key |> to_string() |> String.replace("_", "-")} #{value}"
    end)
  end

  @spec format_origin(origin()) :: String.t()
  defp format_origin(%{scheme: scheme, host: host, port: port}) do
    "#{scheme}://#{host}#{port_segment(port)}"
  end

  defp port_segment(port) when port in [80, 443], do: ""
  defp port_segment(port), do: ":#{port}"

  defp ws_scheme("https"), do: "wss"
  defp ws_scheme("http"), do: "ws"

  @spec additional_hosts() :: [String.t()]
  defp additional_hosts do
    "CSP_ADDITIONAL_HOSTS"
    |> System.get_env("")
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp report_only? do
    :portfolio
    |> Application.get_env(:csp, [])
    |> Keyword.get(:report_only, false)
  end

  defp env_module do
    case Application.get_env(:portfolio, :environment) do
      :dev -> __MODULE__.Dev
      _ -> __MODULE__.Prod
    end
  end
end
