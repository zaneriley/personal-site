defmodule Portfolio.Content.Publishing do
  @moduledoc """
  Coordinates content publication ledger, generations, and current state.

  The append-only ledger records what happened. The singleton state answers what
  is live. Publication generations are the double buffer: rows are written for a
  prepared generation before the state flips visitors to it.
  """

  import Ecto.Query

  alias Portfolio.Content.PublicationControl.Scope
  alias Portfolio.Content.Schemas.CaseStudy
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Content.Schemas.PublicationGeneration
  alias Portfolio.Content.Schemas.PublicationLedgerEntry
  alias Portfolio.Content.Schemas.PublicationState
  alias Portfolio.Repo

  @state_name "default"
  @publication_lock_key 8_312_448_407
  @accepted_statuses ~w(accepted rollback)
  @rollbackable_generation_statuses ~w(live superseded)

  @type publication_status ::
          :accepted | :rejected | :ignored | :duplicate | :rollback | String.t()
  @type publication_lock_result :: term()
  @type rollback_result :: %{
          status: String.t(),
          content_sha: String.t(),
          generation_id: Ecto.UUID.t(),
          previous_generation_id: Ecto.UUID.t() | nil,
          ledger_entry_id: Ecto.UUID.t(),
          reason: String.t()
        }
  @type rollback_error ::
          :no_live_generation
          | {:already_live, Ecto.UUID.t()}
          | {:ambiguous_content_sha, String.t(), [PublicationGeneration.t()]}
          | {:generation_not_rollbackable, Ecto.UUID.t()}
          | {:invalid_rollback_target, String.t()}
          | {:rollback_target_not_found, String.t()}
          | Ecto.Changeset.t()

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
  Rolls live content back to a previous publication generation.

  The target may be a publication generation ID or an unambiguous content SHA.
  Rollback is content-only: it appends a rollback ledger event and flips the
  live generation pointer without fetching from Git or changing the app release.
  """
  @spec rollback(Scope.t(), String.t(), keyword()) ::
          {:ok, rollback_result()} | {:error, rollback_error()}
  def rollback(%Scope{} = scope, target, opts \\ []) when is_binary(target) do
    with_publication_lock(fn ->
      rollback_with_lock(scope, target, opts)
    end)
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
      current: nil,
      current_generation_id: nil,
      live: nil,
      live_generation_id: nil,
      last_good: nil,
      last_good_generation_id: nil,
      last_accepted: nil,
      last_rejected: nil,
      last_rejected_sha: nil,
      last_rejected_reason: nil,
      last_ignored: nil,
      last_ignored_sha: nil,
      last_ignored_reason: nil,
      last_delivery_id: nil,
      sync_state: "missing",
      last_failure_reason: nil
    }
  end

  defp status_from_state(state) do
    %{
      current: state.live_content_sha,
      current_generation_id: state.live_content_publication_generation_id,
      live: state.live_content_sha,
      live_generation_id: state.live_content_publication_generation_id,
      last_good: state.last_good_content_sha,
      last_good_generation_id:
        state.last_good_content_publication_generation_id,
      last_accepted: state.last_accepted_content_sha,
      last_rejected: rejected_status(state),
      last_rejected_sha: state.last_rejected_content_sha,
      last_rejected_reason: state.last_rejected_reason,
      last_ignored: ignored_status(state),
      last_ignored_sha: state.last_ignored_content_sha,
      last_ignored_reason: state.last_ignored_reason,
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
      "Current/live content SHA: #{value_or_none(status.current)}",
      "Current/live generation ID: #{value_or_none(status.current_generation_id)}",
      "Last-good content SHA: #{value_or_none(status.last_good)}",
      "Last-good generation ID: #{value_or_none(status.last_good_generation_id)}",
      "Last accepted SHA: #{value_or_none(status.last_accepted)}",
      "Last rejected SHA: #{value_or_none(status.last_rejected_sha)}",
      "Last rejected reason: #{value_or_none(status.last_rejected_reason)}",
      "Last ignored SHA: #{value_or_none(status.last_ignored_sha)}",
      "Last ignored reason: #{value_or_none(status.last_ignored_reason)}",
      "Last delivery ID: #{value_or_none(status.last_delivery_id)}",
      "Sync state: #{status.sync_state}",
      "Last failure reason: #{value_or_none(status.last_failure_reason)}",
      failures_text(status.recent_failures)
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp rollback_with_lock(%Scope{}, target, opts) do
    with {:ok, generation} <- resolve_rollback_target(target),
         {:ok, previous_generation_id} <-
           previous_live_generation_id(generation),
         {:ok, entry} <- insert_rollback_event(generation, opts) do
      {:ok,
       %{
         status: entry.status,
         content_sha: entry.content_sha,
         generation_id: generation.id,
         previous_generation_id: previous_generation_id,
         ledger_entry_id: entry.id,
         reason: entry.reason
       }}
    end
  end

  defp resolve_rollback_target(target) do
    cond do
      content_sha?(target) -> resolve_rollback_content_sha(target)
      uuid?(target) -> resolve_rollback_generation_id(target)
      true -> {:error, {:invalid_rollback_target, target}}
    end
  end

  defp resolve_rollback_content_sha(content_sha) do
    case rollbackable_generations_by_sha(content_sha) do
      [] ->
        {:error, {:rollback_target_not_found, content_sha}}

      [generation] ->
        {:ok, generation}

      generations ->
        {:error, {:ambiguous_content_sha, content_sha, generations}}
    end
  end

  defp resolve_rollback_generation_id(generation_id) do
    case Repo.get(PublicationGeneration, generation_id) do
      nil ->
        {:error, {:rollback_target_not_found, generation_id}}

      %PublicationGeneration{} = generation ->
        if rollbackable_generation?(generation) do
          {:ok, generation}
        else
          {:error, {:generation_not_rollbackable, generation.id}}
        end
    end
  end

  defp rollbackable_generations_by_sha(content_sha) do
    PublicationGeneration
    |> join(
      :inner,
      [generation],
      entry in PublicationLedgerEntry,
      on: entry.content_publication_generation_id == generation.id
    )
    |> where(
      [generation, entry],
      generation.content_sha == ^content_sha and
        generation.status in ^@rollbackable_generation_statuses and
        entry.status in ^@accepted_statuses
    )
    |> order_by([generation], asc: generation.inserted_at)
    |> Repo.all()
    |> Enum.uniq_by(& &1.id)
    |> Enum.filter(&live_generation_has_published_content?(&1.id))
  end

  defp previous_live_generation_id(%PublicationGeneration{id: generation_id}) do
    case ensure_state!() do
      %PublicationState{live_content_publication_generation_id: nil} ->
        {:error, :no_live_generation}

      %PublicationState{live_content_publication_generation_id: ^generation_id} ->
        {:error, {:already_live, generation_id}}

      %PublicationState{live_content_publication_generation_id: previous_id} ->
        {:ok, previous_id}
    end
  end

  defp insert_rollback_event(%PublicationGeneration{} = generation, opts) do
    delivery_id =
      Keyword.get(opts, :github_delivery_id) ||
        "operator:rollback:#{Ecto.UUID.generate()}"

    reason =
      Keyword.get(
        opts,
        :reason,
        "Operator rollback to generation #{generation.id}"
      )

    opts =
      opts
      |> Keyword.put(:generation_id, generation.id)
      |> Keyword.put(:reason, reason)
      |> Keyword.put_new(:structured_errors, %{"errors" => []})

    record_publication_event(
      delivery_id,
      generation.content_sha,
      :rollback,
      opts
    )
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

    if normalized_status in @accepted_statuses do
      validate_accepted_generation(content_sha, opts)
    else
      :ok
    end
  end

  defp validate_accepted_generation(content_sha, opts) do
    generation_id = Keyword.get(opts, :generation_id)

    cond do
      is_nil(generation_id) ->
        publication_event_error(
          content_sha,
          :accepted,
          "is required for accepted publication events"
        )

      not generation_matches_content_sha?(generation_id, content_sha) ->
        publication_event_error(
          content_sha,
          :accepted,
          "must match the accepted content SHA"
        )

      not live_generation_has_published_content?(generation_id) ->
        publication_event_error(
          content_sha,
          :accepted,
          "must contain published content before acceptance"
        )

      true ->
        :ok
    end
  end

  defp publication_event_error(content_sha, status, message) do
    attrs = %{
      github_delivery_id: "validation",
      content_sha: content_sha,
      status: normalize_status(status)
    }

    changeset =
      %PublicationLedgerEntry{}
      |> PublicationLedgerEntry.changeset(attrs)
      |> Ecto.Changeset.add_error(
        :content_publication_generation_id,
        message
      )

    {:error, changeset}
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
         %PublicationLedgerEntry{status: "accepted"} = entry,
         opts
       ) do
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
         %PublicationLedgerEntry{status: "rollback"} = entry,
         opts
       ) do
    generation_id = Keyword.fetch!(opts, :generation_id)
    state = ensure_state!()
    old_generation_id = state.live_content_publication_generation_id

    supersede_generation(old_generation_id, generation_id)
    set_generation_status(generation_id, "live")

    update_state(%{
      live_content_sha: entry.content_sha,
      last_good_content_sha: entry.content_sha,
      last_delivery_id: entry.github_delivery_id,
      current_sync_state: "idle",
      last_failure_reason: nil,
      live_content_publication_generation_id: generation_id,
      last_good_content_publication_generation_id: generation_id
    })
  end

  defp update_state_for_entry(
         %PublicationLedgerEntry{status: "rejected"} = entry,
         opts
       ) do
    fail_rejected_generation(entry, opts)

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

  defp fail_rejected_generation(entry, opts) do
    case Keyword.get(opts, :generation_id) do
      generation_id when is_binary(generation_id) ->
        generation = Repo.get!(PublicationGeneration, generation_id)

        if generation.content_sha == entry.content_sha and
             generation.status != "live" do
          set_generation_status(generation_id, "failed")
        else
          :ok
        end

      _ ->
        :ok
    end
  end

  defp set_generation_status(generation_id, status) do
    generation = Repo.get!(PublicationGeneration, generation_id)

    generation
    |> PublicationGeneration.changeset(%{status: status})
    |> Repo.update!()
  end

  defp generation_matches_content_sha?(generation_id, content_sha) do
    PublicationGeneration
    |> where(
      [generation],
      generation.id == ^generation_id and generation.content_sha == ^content_sha
    )
    |> Repo.exists?()
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
        content.is_draft == false and not is_nil(content.published_at)
    )
    |> Repo.exists?()
  end

  defp rollbackable_generation?(%PublicationGeneration{
         id: generation_id,
         status: status
       })
       when status in @rollbackable_generation_statuses do
    has_rollback_capable_event? =
      PublicationLedgerEntry
      |> where(
        [entry],
        entry.content_publication_generation_id == ^generation_id and
          entry.status in ^@accepted_statuses
      )
      |> Repo.exists?()

    has_rollback_capable_event? and
      live_generation_has_published_content?(generation_id)
  end

  defp rollbackable_generation?(%PublicationGeneration{}), do: false

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

  defp value_or_none(nil), do: "none"
  defp value_or_none(value), do: value

  defp content_sha?(target) when is_binary(target) do
    String.match?(target, ~r/\A[0-9a-f]{40}\z/i)
  end

  defp uuid?(target) when is_binary(target) do
    match?({:ok, _uuid}, Ecto.UUID.cast(target))
  end

  defp normalize_status(status) when is_atom(status), do: Atom.to_string(status)
  defp normalize_status(status) when is_binary(status), do: status

  defp normalize_source(source) when is_atom(source), do: Atom.to_string(source)
  defp normalize_source(source) when is_binary(source), do: source

  defp utc_now do
    DateTime.utc_now()
  end
end
