defmodule PortfolioWeb.ContentWebhookController do
  @moduledoc """
  Handles incoming GitHub webhook payloads for content updates.

  This controller is responsible for processing webhook payloads from GitHub,
  determining if they contain relevant changes to the content, and triggering
  content updates when necessary.

  ## Key functions

  - `handle_push/2`: Entrypoint for processing webhook payloads
  - `process_payload/1`: Determines if a payload contains relevant changes
  - `trigger_update/0`: Initiates the content update process

  ## Dependencies

  This module relies on:
  - `Portfolio.Content.Remote.RemoteUpdateTrigger` for triggering updates
  - `Portfolio.Content.Types` for determining content types
  """

  require Logger
  use PortfolioWeb, :controller
  alias Portfolio.Content.Remote.RemoteUpdateTrigger
  alias Portfolio.Content.Types

  @doc """
  Processes the webhook payload and determines if an update is needed.

  This function examines the payload for relevant file changes and triggers
  an update if necessary.

  ## Parameters

  - `payload`: A map containing the webhook payload from GitHub

  ## Returns

  - `{:ok, :updated}` if relevant changes were found and an update was triggered
  - `{:ok, :no_relevant_changes}` if no relevant changes were found
  - `{:error, reason}` if an error occurred during processing

  ## Examples

      iex> payload = %{"commits" => [%{"added" => ["content/new_post.md"]}]}
      iex> ContentWebhookController.process_payload(payload)
      {:ok, :updated}

  """
  @spec handle_push(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def handle_push(conn, %{"payload" => payload}) do
    Logger.info("Received webhook payload: #{inspect(payload)}")

    payload
    |> validate_payload()
    |> process_payload()
    |> handle_process_result(conn)
  end

  @spec validate_payload(map()) ::
          {:ok, map()} | {:error, :invalid_payload, String.t()}
  defp validate_payload(payload) do
    cond do
      is_nil(payload["repository"]) ->
        {:error, :invalid_payload, "Missing repository information"}

      is_nil(payload["commits"]) ->
        {:error, :invalid_payload, "Missing commits information"}

      true ->
        {:ok, payload}
    end
  end

  @spec process_payload({:ok, map()} | {:error, :invalid_payload, String.t()}) ::
          {:ok, :updated | :no_relevant_changes}
          | {:error, :invalid_payload, String.t()}
          | {:error, any()}
  defp process_payload({:error, _, _} = error), do: error

  defp process_payload({:ok, payload}) do
    if payload_has_relevant_changes?(payload) do
      Logger.info("Relevant file changes detected")
      trigger_update()
    else
      Logger.info("No relevant file changes detected")
      {:ok, :no_relevant_changes}
    end
  end

  @spec payload_has_relevant_changes?(map()) :: boolean()
  defp payload_has_relevant_changes?(payload) do
    payload
    |> extract_changed_files()
    |> Enum.any?(&relevant_file_change?/1)
  end

  @spec extract_changed_files(map()) :: [String.t()]
  defp extract_changed_files(payload) do
    payload["commits"]
    |> Enum.flat_map(fn commit ->
      (commit["added"] || []) ++ (commit["modified"] || [])
    end)
  end

  @spec relevant_file_change?(String.t()) :: boolean()
  defp relevant_file_change?(path) do
    with true <- Path.extname(path) == ".md",
         true <- not String.starts_with?(Path.basename(path), "."),
         {:ok, _type} <- Types.get_type(path) do
      true
    else
      _ -> false
    end
  end

  @spec trigger_update() :: {:ok, :updated} | {:error, any()}
  defp trigger_update() do
    Logger.info("Triggering update with RemoteUpdateTrigger")

    case RemoteUpdateTrigger.trigger_update(content_repo_url()) do
      {:ok, _} = result ->
        Logger.info("RemoteUpdateTrigger completed successfully")
        result

      {:error, reason} = error ->
        Logger.error("RemoteUpdateTrigger failed: #{inspect(reason)}")
        error
    end
  end

  @spec handle_process_result(
          {:ok, :updated | :no_relevant_changes}
          | {:error, :invalid_payload, String.t()}
          | {:error, any()},
          Plug.Conn.t()
        ) :: Plug.Conn.t()
  defp handle_process_result({:ok, :updated}, conn) do
    Logger.info("Webhook processed successfully")

    send_json_resp(conn, :ok, %{
      message: "Content update process initiated successfully"
    })
  end

  defp handle_process_result({:ok, :no_relevant_changes}, conn) do
    Logger.info("No relevant changes detected")
    send_json_resp(conn, :ok, %{message: "No relevant changes detected"})
  end

  defp handle_process_result({:error, :invalid_payload, message}, conn) do
    Logger.warning("Invalid payload received: #{message}")

    send_json_resp(conn, :bad_request, %{
      error: "Invalid payload",
      message: message
    })
  end

  defp handle_process_result({:error, reason}, conn) do
    Logger.error("Failed to process webhook: #{inspect(reason)}")

    send_json_resp(conn, :internal_server_error, %{
      error: "Internal server error"
    })
  end

  # Updated helper function to send JSON responses
  defp send_json_resp(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(Plug.Conn.Status.code(status), Jason.encode!(data))
  end

  defp content_repo_url do
    Application.get_env(:portfolio, :content_repo_url)
  end
end
