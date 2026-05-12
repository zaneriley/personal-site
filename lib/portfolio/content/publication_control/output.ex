defmodule Portfolio.Content.PublicationControl.Output do
  @moduledoc """
  Formats content publication control results for operator command surfaces.
  """

  @type rollback_error ::
          :no_live_generation
          | {:already_live, Ecto.UUID.t()}
          | {:ambiguous_content_sha, String.t(), [map()]}
          | {:generation_not_rollbackable, Ecto.UUID.t()}
          | {:invalid_rollback_target, String.t()}
          | {:rollback_target_not_found, String.t()}
          | {:usage, String.t()}
          | Ecto.Changeset.t()

  @doc """
  Converts a successful rollback result into stable JSON data.
  """
  @spec success_json(map()) :: map()
  def success_json(result) do
    Map.put(result, :result, "ok")
  end

  @doc """
  Converts a successful rollback result into operator-facing text.
  """
  @spec success_text(map()) :: String.t()
  def success_text(result) do
    """
    Rolled back content to generation #{result.generation_id}
    Content SHA: #{result.content_sha}
    Previous live generation: #{result.previous_generation_id}
    Ledger entry: #{result.ledger_entry_id}
    Reason: #{result.reason}
    """
  end

  @doc """
  Converts a rollback failure into stable JSON data.
  """
  @spec error_json(rollback_error()) :: map()
  def error_json({:ambiguous_content_sha, content_sha, generations}) do
    %{
      status: "error",
      reason: "ambiguous_content_sha",
      content_sha: content_sha,
      matching_generation_ids: Enum.map(generations, & &1.id)
    }
  end

  def error_json({:already_live, generation_id}) do
    %{
      status: "error",
      reason: "already_live",
      generation_id: generation_id
    }
  end

  def error_json({:generation_not_rollbackable, generation_id}) do
    %{
      status: "error",
      reason: "generation_not_rollbackable",
      generation_id: generation_id
    }
  end

  def error_json({:invalid_rollback_target, target}) do
    %{
      status: "error",
      reason: "invalid_rollback_target",
      target: target
    }
  end

  def error_json({:rollback_target_not_found, target}) do
    %{
      status: "error",
      reason: "rollback_target_not_found",
      target: target
    }
  end

  def error_json(:no_live_generation) do
    %{
      status: "error",
      reason: "no_live_generation"
    }
  end

  def error_json({:usage, usage}) do
    %{
      status: "error",
      reason: "usage",
      usage: usage
    }
  end

  def error_json(%Ecto.Changeset{} = changeset) do
    %{
      status: "error",
      reason: "changeset",
      errors: inspect(changeset.errors)
    }
  end

  @doc """
  Converts a rollback failure into operator-facing text.
  """
  @spec error_text(rollback_error()) :: String.t()
  def error_text({:ambiguous_content_sha, content_sha, generations}) do
    generation_ids =
      generations
      |> Enum.map_join("\n", fn generation -> "- #{generation.id}" end)

    """
    Content SHA #{content_sha} is ambiguous. Choose a generation ID:
    #{generation_ids}
    """
  end

  def error_text({:already_live, generation_id}) do
    "Generation #{generation_id} is already live."
  end

  def error_text({:generation_not_rollbackable, generation_id}) do
    "Generation #{generation_id} is not rollback-capable."
  end

  def error_text({:invalid_rollback_target, target}) do
    "Invalid rollback target: #{target}"
  end

  def error_text({:rollback_target_not_found, target}) do
    "Rollback target not found: #{target}"
  end

  def error_text(:no_live_generation) do
    "No live content generation exists to roll back from."
  end

  def error_text({:usage, usage}), do: usage

  def error_text(%Ecto.Changeset{} = changeset), do: inspect(changeset.errors)
end
