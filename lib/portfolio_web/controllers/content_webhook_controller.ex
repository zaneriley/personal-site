defmodule PortfolioWeb.ContentWebhookController do
  @moduledoc """
  Handles incoming GitHub webhook payloads for content updates.

  This controller processes webhook payloads from GitHub,
  determines if they contain relevant changes to the content,
  and triggers content updates when necessary.
  """

  require Logger
  alias Portfolio.Content.Remote.RemoteUpdateTrigger
  alias Portfolio.Content.Types

  @type webhook_result ::
          {:ok, :updated | :no_relevant_changes} | {:error, String.t()}

  @spec handle_webhook(Plug.Conn.t(), map(), keyword()) :: webhook_result()
  def handle_webhook(_conn, payload, opts) do
    Logger.info("Processing webhook payload")

    with {:ok, event_type} <- extract_event_type(payload),
         :ok <- validate_push_event(event_type),
         {:ok, relevant_changes} <- extract_relevant_changes(payload) do
      case relevant_changes do
        [] ->
          Logger.info("No relevant file changes detected")
          {:ok, :no_relevant_changes}

        changes ->
          Logger.info("Relevant file changes detected: #{inspect(changes)}")
          trigger_update(opts)
      end
    else
      {:error, reason} ->
        Logger.warn("Error processing webhook: #{reason}")
        {:error, reason}
    end
  end

  @spec extract_event_type(map()) :: {:ok, String.t()} | {:error, String.t()}
  defp extract_event_type(%{"commits" => _}) do
    {:ok, "push"}
  end

  defp extract_event_type(_) do
    {:error, "Invalid or unsupported event type"}
  end

  @spec validate_push_event(String.t()) :: :ok | {:error, String.t()}
  defp validate_push_event("push"), do: :ok
  defp validate_push_event(_), do: {:error, "Only push events are supported"}

  @spec extract_relevant_changes(map()) ::
          {:ok, [String.t()]} | {:error, String.t()}
  defp extract_relevant_changes(%{"commits" => commits})
       when is_list(commits) do
    relevant_changes =
      commits
      |> Stream.flat_map(fn commit ->
        (commit["added"] || []) ++ (commit["modified"] || [])
      end)
      |> Stream.uniq()
      |> Stream.filter(&relevant_file_change?/1)
      |> Enum.to_list()

    {:ok, relevant_changes}
  end

  defp extract_relevant_changes(_), do: {:error, "Invalid payload structure"}

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

  @spec trigger_update(keyword()) :: webhook_result()
  defp trigger_update(opts) do
    Logger.info("Triggering update with RemoteUpdateTrigger")

    case RemoteUpdateTrigger.trigger_update(content_repo_url(opts)) do
      {:ok, _} ->
        Logger.info("RemoteUpdateTrigger completed successfully")
        {:ok, :updated}

      {:error, reason} ->
        Logger.error("RemoteUpdateTrigger failed: #{inspect(reason)}")
        {:error, "Update failed: #{inspect(reason)}"}
    end
  end

  @spec content_repo_url(keyword()) :: String.t()
  defp content_repo_url(opts) do
    Keyword.get(opts, :content_repo_url) ||
      Application.fetch_env!(:portfolio, :content_repo_url)
  end
end
