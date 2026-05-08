defmodule PortfolioWeb.ContentWebhookController do
  @moduledoc """
  Handles incoming GitHub webhook payloads for content updates.

  This controller processes webhook payloads from GitHub,
  determines if they contain relevant changes to the content,
  and triggers content updates when necessary.
  """

  require Logger
  alias Portfolio.Content
  alias Portfolio.Content.Remote.RemoteUpdateTrigger
  alias Portfolio.Content.Types

  @type webhook_result ::
          {:ok, map() | :no_relevant_changes} | {:error, String.t()}

  @type relevant_changes :: %{upsert: [String.t()], delete: [String.t()]}

  @main_ref "refs/heads/main"
  @zero_sha String.duplicate("0", 40)

  @spec handle_webhook(Plug.Conn.t(), map(), keyword()) :: webhook_result()
  def handle_webhook(_conn, payload, opts) do
    Logger.info("Processing webhook payload")

    with {:ok, event_type} <- extract_event_type(payload),
         :ok <- validate_push_event(event_type),
         :ok <- validate_ref(payload),
         :ok <- validate_repository(payload, content_repo_url(opts)),
         {:ok, target_sha} <- extract_target_sha(payload),
         {:ok, relevant_changes} <- extract_relevant_changes(payload) do
      if empty_changes?(relevant_changes) do
        record_ignored_update(target_sha)
      else
        Logger.info(
          "Relevant file changes detected: #{inspect(relevant_changes)}"
        )

        trigger_update(opts, relevant_changes, target_sha)
      end
    else
      {:error, reason} ->
        Logger.warning("Error processing webhook: #{reason}")
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

  @spec validate_ref(map()) :: :ok | {:error, String.t()}
  defp validate_ref(%{"ref" => @main_ref}), do: :ok
  defp validate_ref(%{"ref" => ref}), do: {:error, "Unexpected ref: #{ref}"}
  defp validate_ref(_), do: {:error, "Missing ref"}

  @spec validate_repository(map(), String.t()) :: :ok | {:error, String.t()}
  defp validate_repository(%{"repository" => repository}, expected_repo_url) do
    clone_url = repository["clone_url"]
    ssh_url = repository["ssh_url"]

    if expected_repo_url in [clone_url, ssh_url] do
      :ok
    else
      {:error, "Unexpected repository"}
    end
  end

  defp validate_repository(_, _expected_repo_url),
    do: {:error, "Missing repository"}

  @spec extract_target_sha(map()) :: {:ok, String.t()} | {:error, String.t()}
  defp extract_target_sha(%{"after" => @zero_sha}),
    do: {:error, "Branch deletion is not supported"}

  defp extract_target_sha(%{"after" => sha})
       when is_binary(sha) and byte_size(sha) == 40 do
    if String.match?(sha, ~r/\A[0-9a-f]{40}\z/i) do
      {:ok, sha}
    else
      {:error, "Invalid after SHA"}
    end
  end

  defp extract_target_sha(_), do: {:error, "Missing after SHA"}

  @spec extract_relevant_changes(map()) ::
          {:ok, relevant_changes()} | {:error, String.t()}
  defp extract_relevant_changes(%{"commits" => commits})
       when is_list(commits) do
    upsert =
      commits
      |> changed_paths(["added", "modified"])
      |> Enum.filter(&relevant_file_change?/1)

    delete =
      commits
      |> changed_paths(["removed"])
      |> Enum.filter(&relevant_file_change?/1)

    {:ok, %{upsert: upsert, delete: delete}}
  end

  defp extract_relevant_changes(_), do: {:error, "Invalid payload structure"}

  defp changed_paths(commits, keys) do
    commits
    |> Stream.flat_map(fn commit ->
      Enum.flat_map(keys, &(commit[&1] || []))
    end)
    |> Stream.uniq()
    |> Enum.to_list()
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

  @spec empty_changes?(relevant_changes()) :: boolean()
  defp empty_changes?(%{upsert: [], delete: []}), do: true
  defp empty_changes?(_changes), do: false

  @spec record_ignored_update(String.t()) :: webhook_result()
  defp record_ignored_update(target_sha) do
    Logger.info("No relevant file changes detected")

    case Content.record_publication_verdict(target_sha, :ignored,
           reason: "No relevant content changes"
         ) do
      {:ok, _verdict} ->
        {:ok, :no_relevant_changes}

      {:error, changeset} ->
        Logger.error(
          "Failed to record ignored content verdict: #{inspect(changeset)}"
        )

        {:error, "Publication verdict recording failed"}
    end
  end

  @spec trigger_update(keyword(), relevant_changes(), String.t()) ::
          webhook_result()
  defp trigger_update(opts, changes, target_sha) do
    Logger.info("Triggering update with RemoteUpdateTrigger")

    case RemoteUpdateTrigger.trigger_update(content_repo_url(opts),
           content_base_path: Keyword.get(opts, :content_base_path),
           changes: changes,
           target_sha: target_sha
         ) do
      {:ok, result} ->
        Logger.info("RemoteUpdateTrigger completed successfully")
        {:ok, result}

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
