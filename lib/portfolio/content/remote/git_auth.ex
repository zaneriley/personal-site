defmodule Portfolio.Content.Remote.GitAuth do
  @moduledoc """
  Resolves ephemeral Git authentication for content repository syncs.

  Credentials are injected through environment variables at command execution
  time. They are never embedded in the repository URL, command arguments, or
  persisted Git config.
  """

  @base_env [{"GIT_TERMINAL_PROMPT", "0"}]
  @default_askpass_path "/app/bin/content-git-askpass"
  @default_username "x-access-token"

  @enforce_keys [:env, :redactions]
  defstruct [:env, :redactions]

  @type t :: %__MODULE__{
          env: [{String.t(), String.t()}],
          redactions: [String.t()]
        }

  @doc """
  Returns unauthenticated Git command settings.
  """
  @spec none() :: t()
  def none do
    %__MODULE__{env: @base_env, redactions: []}
  end

  @doc """
  Resolves Git auth for the configured content repository URL.
  """
  @spec resolve(String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def resolve(repo_url, opts \\ []) when is_binary(repo_url) do
    with :ok <- validate_clean_repo_url(repo_url) do
      config = auth_config(opts)

      {:ok,
       %__MODULE__{
         env: @base_env ++ auth_env(config),
         redactions: redactions(config)
       }}
    end
  end

  @doc """
  Returns the Git command environment for an auth configuration.
  """
  @spec env(t()) :: [{String.t(), String.t()}]
  def env(%__MODULE__{env: env}), do: env

  @doc """
  Replaces configured secrets in command output or log messages.
  """
  @spec sanitize(t(), String.t()) :: String.t()
  def sanitize(%__MODULE__{redactions: redactions}, value)
      when is_binary(value) do
    Enum.reduce(redactions, value, fn secret, acc ->
      String.replace(acc, secret, "[REDACTED]")
    end)
  end

  @spec sanitize(t(), term()) :: term()
  def sanitize(%__MODULE__{}, value), do: value

  defp validate_clean_repo_url(repo_url) do
    case URI.parse(repo_url) do
      %URI{userinfo: userinfo} when is_binary(userinfo) ->
        {:error, "Content repo URL must not contain credentials"}

      %URI{} ->
        :ok
    end
  end

  defp auth_config(opts) do
    Keyword.get(opts, :auth) ||
      Application.get_env(:portfolio, :content_repo_auth, [])
  end

  defp auth_env(config) do
    []
    |> maybe_put_ssh_command(config)
    |> maybe_put_https_token(config)
  end

  defp maybe_put_ssh_command(env, config) do
    case presence(Keyword.get(config, :ssh_command)) do
      nil -> env
      ssh_command -> [{"GIT_SSH_COMMAND", ssh_command} | env]
    end
  end

  defp maybe_put_https_token(env, config) do
    case presence(Keyword.get(config, :https_token)) do
      nil ->
        env

      token ->
        askpass_path =
          config
          |> Keyword.get(:askpass_path, @default_askpass_path)
          |> presence()

        username =
          config
          |> Keyword.get(:username, @default_username)
          |> presence()

        [
          {"GIT_ASKPASS", askpass_path || @default_askpass_path},
          {"CONTENT_REPO_GIT_USERNAME", username || @default_username},
          {"CONTENT_REPO_HTTPS_TOKEN", token}
          | env
        ]
    end
  end

  defp redactions(config) do
    config
    |> Keyword.get(:https_token)
    |> presence()
    |> List.wrap()
  end

  defp presence(value) when is_binary(value) do
    if String.trim(value) == "" do
      nil
    else
      value
    end
  end

  defp presence(nil), do: nil
end
