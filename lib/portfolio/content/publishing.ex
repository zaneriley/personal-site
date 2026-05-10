defmodule Portfolio.Content.Publishing do
  @moduledoc """
  Coordinates content publication ledger, generations, and current state.

  The append-only ledger records what happened. The singleton state answers what
  is live. Publication generations are the double buffer: rows are written for a
  prepared generation before the state flips visitors to it.
  """

  import Ecto.Query

  alias Portfolio.Content.Schemas.CaseStudy
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Content.Schemas.PublicationGeneration
  alias Portfolio.Content.Schemas.PublicationLedgerEntry
  alias Portfolio.Content.Schemas.PublicationState
  alias Portfolio.Repo

  @state_name "default"
  @publication_lock_key 8_312_448_407
  @accepted_statuses ~w(accepted rollback)

  @type publication_status ::
          :accepted | :rejected | :ignored | :duplicate | :rollback | String.t()
  @type publication_lock_result :: term()

  @doc """
  Runs a function while holding the database-backed publication lock.
  """
  @spec with_publication_lock((-> publication_lock_result())) ::
          publication_lock_result()
  def with_publication_lock(fun) when is_function(fun, 0) do
    result =
      Repo.transaction(
        fn ->
          Repo.query!("SELECT pg_advisory_xact_lock($1)", [
            @publication_lock_key
          ])

          fun.()
        end,
        timeout: :infinity
      )

    case result do
      {:ok, result} -> result
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Creates a prepared publication generation.
  """
  @spec prepare_generation(String.t(), keyword()) ::
          {:ok, PublicationGeneration.t()} | {:error, Ecto.Changeset.t()}
  def prepare_generation(content_sha, opts \\ []) when is_binary(content_sha) do
    attrs = %{
      content_sha: content_sha,
      source: opts |> Keyword.get(:source, :publish) |> normalize_source(),
      status: "preparing"
    }

    %PublicationGeneration{}
    |> PublicationGeneration.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Records a publication event and updates the read model.

  Duplicate `github_delivery_id` values return the existing entry without
  appending a second ledger row or changing publication state.
  """
  @spec record_publication_event(
          String.t(),
          String.t(),
          publication_status(),
          keyword()
        ) ::
          {:ok, PublicationLedgerEntry.t()}
          | {:error, Ecto.Changeset.t()}
  def record_publication_event(
        github_delivery_id,
        content_sha,
        status,
        opts \\ []
      )
      when is_binary(github_delivery_id) and is_binary(content_sha) do
    case get_ledger_entry_by_delivery_id(github_delivery_id) do
      nil ->
        with :ok <- validate_publication_event_opts(content_sha, status, opts) do
          insert_publication_event(
            github_delivery_id,
            content_sha,
            status,
            opts
          )
        end

      %PublicationLedgerEntry{} = entry ->
        {:ok, entry}
    end
  end

  @doc """
  Marks publication sync as running in the current state read model.
  """
  @spec mark_sync_running(String.t()) ::
          {:ok, PublicationState.t()} | {:error, Ecto.Changeset.t()}
  def mark_sync_running(delivery_id) when is_binary(delivery_id) do
    update_state(%{
      last_delivery_id: delivery_id,
      current_sync_state: "running",
      last_failure_reason: nil
    })
  end

  @doc """
  Marks publication sync as failed when no content SHA verdict can be recorded.
  """
  @spec mark_sync_failed(String.t(), String.t()) ::
          {:ok, PublicationState.t()} | {:error, Ecto.Changeset.t()}
  def mark_sync_failed(delivery_id, reason)
      when is_binary(delivery_id) and is_binary(reason) do
    update_state(%{
      last_delivery_id: delivery_id,
      current_sync_state: "failed",
      last_failure_reason: reason
    })
  end

  @doc """
  Returns the singleton content publication state.
  """
  @spec get_publication_state(keyword()) :: PublicationState.t() | nil
  def get_publication_state(opts \\ []) do
    repo_opts = Keyword.take(opts, [:log])

    Repo.get_by(PublicationState, [name: @state_name], repo_opts)
  end

  @doc """
  Returns the live publication generation ID, if content has been accepted.
  """
  @spec live_generation_id() :: Ecto.UUID.t() | nil
  def live_generation_id do
    case get_publication_state() do
      nil -> nil
      state -> state.live_content_publication_generation_id
    end
  end

  @doc """
  Returns true when the app has live content selected by the publication state.
  """
  @spec content_ready?() :: boolean()
  def content_ready? do
    with %PublicationState{
           live_content_sha: sha,
           live_content_publication_generation_id: generation_id
         }
         when is_binary(sha) and is_binary(generation_id) <-
           get_publication_state(),
         true <- live_generation_ready?(generation_id, sha),
         true <- live_generation_has_published_content?(generation_id) do
      true
    else
      _ -> false
    end
  end

  @doc """
  Returns true when storage responds and accepted content is live.
  """
  @spec ready?() :: boolean()
  def ready? do
    storage_ready?() and content_ready?()
  end

  @doc """
  Fetches a ledger entry by GitHub delivery ID.
  """
  @spec get_ledger_entry_by_delivery_id(String.t()) ::
          PublicationLedgerEntry.t() | nil
  def get_ledger_entry_by_delivery_id(github_delivery_id)
      when is_binary(github_delivery_id) do
    Repo.get_by(PublicationLedgerEntry, github_delivery_id: github_delivery_id)
  end

  @doc """
  Fetches the latest publication ledger entry for a content SHA.
  """
  @spec latest_publication_event(String.t()) :: PublicationLedgerEntry.t() | nil
  def latest_publication_event(content_sha) when is_binary(content_sha) do
    PublicationLedgerEntry
    |> where([entry], entry.content_sha == ^content_sha)
    |> order_by([entry], desc: entry.inserted_at, desc: entry.received_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Returns true when a SHA has an accepted publication event.
  """
  @spec accepted_content_sha?(String.t()) :: boolean()
  def accepted_content_sha?(content_sha) when is_binary(content_sha) do
    PublicationLedgerEntry
    |> where([entry], entry.content_sha == ^content_sha)
    |> where([entry], entry.status in ^@accepted_statuses)
    |> Repo.exists?()
  end

  @doc """
  Returns the current publication state as a plain map for CLIs and status UIs.
  """
  @spec status() :: map()
  def status do
    state = get_publication_state(log: false)

    state
    |> status_from_state()
    |> Map.put(:recent_failures, recent_failures(log: false))
  end

  defp status_from_state(nil) do
    %{
      live: nil,
      last_good: nil,
      last_accepted: nil,
      last_rejected: nil,
      last_ignored: nil,
      last_delivery_id: nil,
      sync_state: "missing",
      last_failure_reason: nil
    }
  end

  defp status_from_state(state) do
    %{
      live: state.live_content_sha,
      last_good: state.last_good_content_sha,
      last_accepted: state.last_accepted_content_sha,
      last_rejected: rejected_status(state),
      last_ignored: ignored_status(state),
      last_delivery_id: state.last_delivery_id,
      sync_state: state.current_sync_state,
      last_failure_reason: state.last_failure_reason
    }
  end

  @doc """
  Formats publication status for operator-facing text output.
  """
  @spec status_text() :: String.t()
  def status_text do
    status = status()

    [
      "Live content SHA: #{status.live || "none"}",
      "Last-good content SHA: #{status.last_good || "none"}",
      "Last accepted SHA: #{status.last_accepted || "none"}",
      "Last rejected SHA: #{verdict_text(status.last_rejected)}",
      "Last ignored SHA: #{verdict_text(status.last_ignored)}",
      "Last delivery ID: #{status.last_delivery_id || "none"}",
      "Sync state: #{status.sync_state}",
      "Last failure reason: #{status.last_failure_reason || "none"}",
      failures_text(status.recent_failures)
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp insert_publication_event(github_delivery_id, content_sha, status, opts) do
    Repo.transaction(fn ->
      with {:ok, entry} <-
             insert_ledger_entry(github_delivery_id, content_sha, status, opts),
           {:ok, _state} <- update_state_for_entry(entry, opts) do
        entry
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp validate_publication_event_opts(content_sha, status, opts) do
    normalized_status = normalize_status(status)

    if normalized_status in @accepted_statuses and
         is_nil(Keyword.get(opts, :generation_id)) do
      attrs = %{
        github_delivery_id: "validation",
        content_sha: content_sha,
        status: normalized_status
      }

      changeset =
        %PublicationLedgerEntry{}
        |> PublicationLedgerEntry.changeset(attrs)
        |> Ecto.Changeset.add_error(
          :content_publication_generation_id,
          "is required for accepted publication events"
        )

      {:error, changeset}
    else
      :ok
    end
  end

  defp insert_ledger_entry(github_delivery_id, content_sha, status, opts) do
    now = utc_now()

    attrs = %{
      github_delivery_id: github_delivery_id,
      content_sha: content_sha,
      status: normalize_status(status),
      repository: Keyword.get(opts, :repository),
      ref: Keyword.get(opts, :ref),
      reason: Keyword.get(opts, :reason),
      content_publication_generation_id: Keyword.get(opts, :generation_id),
      promoted_paths: Keyword.get(opts, :promoted_paths, []),
      removed_paths: Keyword.get(opts, :removed_paths, []),
      skipped_paths: Keyword.get(opts, :skipped_paths, []),
      structured_errors:
        Keyword.get(opts, :structured_errors, %{"errors" => []}),
      received_at: Keyword.get(opts, :received_at, now),
      started_at: Keyword.get(opts, :started_at, now),
      finished_at: Keyword.get(opts, :finished_at, now)
    }

    %PublicationLedgerEntry{}
    |> PublicationLedgerEntry.changeset(attrs)
    |> Repo.insert()
  end

  defp update_state_for_entry(
         %PublicationLedgerEntry{status: status} = entry,
         opts
       )
       when status in @accepted_statuses do
    generation_id = Keyword.fetch!(opts, :generation_id)
    state = ensure_state!()
    old_generation_id = state.live_content_publication_generation_id

    supersede_generation(old_generation_id, generation_id)
    set_generation_status(generation_id, "live")

    update_state(%{
      live_content_sha: entry.content_sha,
      last_good_content_sha: entry.content_sha,
      last_accepted_content_sha: entry.content_sha,
      last_delivery_id: entry.github_delivery_id,
      current_sync_state: "idle",
      last_failure_reason: nil,
      live_content_publication_generation_id: generation_id,
      last_good_content_publication_generation_id: generation_id
    })
  end

  defp update_state_for_entry(
         %PublicationLedgerEntry{status: "rejected"} = entry,
         _opts
       ) do
    update_state(%{
      last_rejected_content_sha: entry.content_sha,
      last_rejected_reason: entry.reason,
      last_delivery_id: entry.github_delivery_id,
      current_sync_state: "failed",
      last_failure_reason: entry.reason
    })
  end

  defp update_state_for_entry(
         %PublicationLedgerEntry{status: "ignored"} = entry,
         _opts
       ) do
    update_state(%{
      last_ignored_content_sha: entry.content_sha,
      last_ignored_reason: entry.reason,
      last_delivery_id: entry.github_delivery_id,
      current_sync_state: "idle",
      last_failure_reason: nil
    })
  end

  defp update_state_for_entry(%PublicationLedgerEntry{} = entry, _opts) do
    update_state(%{
      last_delivery_id: entry.github_delivery_id,
      current_sync_state: "idle"
    })
  end

  defp update_state(attrs) do
    state = ensure_state!()

    state
    |> PublicationState.changeset(Map.put(attrs, :name, @state_name))
    |> Repo.update()
  end

  defp ensure_state! do
    Repo.get_by(PublicationState, name: @state_name) ||
      Repo.insert!(
        PublicationState.changeset(%PublicationState{}, %{name: @state_name})
      )
  end

  defp supersede_generation(nil, _new_generation_id), do: :ok
  defp supersede_generation(same_generation_id, same_generation_id), do: :ok

  defp supersede_generation(generation_id, _new_generation_id) do
    set_generation_status(generation_id, "superseded")
  end

  defp set_generation_status(generation_id, status) do
    generation = Repo.get!(PublicationGeneration, generation_id)

    generation
    |> PublicationGeneration.changeset(%{status: status})
    |> Repo.update!()
  end

  defp live_generation_ready?(generation_id, content_sha) do
    PublicationGeneration
    |> where(
      [generation],
      generation.id == ^generation_id and
        generation.content_sha == ^content_sha and
        generation.status == "live"
    )
    |> Repo.exists?()
  end

  defp live_generation_has_published_content?(generation_id) do
    live_content_exists?(Note, generation_id) ||
      live_content_exists?(CaseStudy, generation_id)
  end

  defp live_content_exists?(schema, generation_id) do
    schema
    |> where(
      [content],
      content.publication_generation_id == ^generation_id and
        content.is_draft == false
    )
    |> Repo.exists?()
  end

  defp storage_ready? do
    case Repo.query("SELECT 1", [], log: false) do
      {:ok, _result} -> true
      {:error, _reason} -> false
    end
  rescue
    DBConnection.ConnectionError -> false
    Postgrex.Error -> false
  end

  defp rejected_status(state) do
    if state.last_rejected_content_sha do
      %{
        content_sha: state.last_rejected_content_sha,
        reason: state.last_rejected_reason
      }
    end
  end

  defp ignored_status(state) do
    if state.last_ignored_content_sha do
      %{
        content_sha: state.last_ignored_content_sha,
        reason: state.last_ignored_reason
      }
    end
  end

  defp recent_failures(opts) do
    repo_opts = Keyword.take(opts, [:log])

    PublicationLedgerEntry
    |> where([entry], entry.status == "rejected")
    |> order_by([entry], desc: entry.inserted_at)
    |> limit(5)
    |> Repo.all(repo_opts)
    |> Enum.map(fn entry ->
      %{
        content_sha: entry.content_sha,
        delivery_id: entry.github_delivery_id,
        reason: entry.reason,
        structured_errors: entry.structured_errors
      }
    end)
  end

  defp failures_text([]), do: ""

  defp failures_text(failures) do
    failures
    |> Enum.map_join("\n", fn failure ->
      "Failure #{failure.delivery_id}: #{failure.content_sha} #{failure.reason}"
    end)
  end

  defp verdict_text(nil), do: "none"

  defp verdict_text(%{content_sha: content_sha, reason: nil}) do
    content_sha
  end

  defp verdict_text(%{content_sha: content_sha, reason: reason}) do
    "#{content_sha} (#{reason})"
  end

  defp normalize_status(status) when is_atom(status), do: Atom.to_string(status)
  defp normalize_status(status) when is_binary(status), do: status

  defp normalize_source(source) when is_atom(source), do: Atom.to_string(source)
  defp normalize_source(source) when is_binary(source), do: source

  defp utc_now do
    DateTime.utc_now()
  end
end
