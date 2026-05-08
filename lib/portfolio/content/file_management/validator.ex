defmodule Portfolio.Content.FileManagement.Validator do
  @moduledoc """
  Validates a checked-out content repository without publishing it.

  Validation intentionally reuses the same promotion path as production content
  updates, then rolls the transaction back. A green result means the content can
  be parsed, validated, compiled, and promoted by the app's current rules.
  """

  alias Portfolio.Content.FileManagement.Promoter
  alias Portfolio.Repo

  @type validation_result :: Promoter.promotion_result()

  @doc """
  Validates all publishable Markdown under `content_base_path`.
  """
  @spec validate_all(String.t()) ::
          {:ok, validation_result()} | {:error, validation_result()}
  def validate_all(content_base_path) when is_binary(content_base_path) do
    content_base_path
    |> Path.expand()
    |> validate_in_rollback_transaction()
  end

  defp validate_in_rollback_transaction(content_base_path) do
    case Repo.transaction(fn -> validate_and_rollback(content_base_path) end) do
      {:error, {:valid, result}} -> {:ok, result}
      {:error, {:invalid, result}} -> {:error, result}
      {:error, reason} -> {:error, transaction_error(reason)}
    end
  end

  defp validate_and_rollback(content_base_path) do
    case Promoter.promote_all(content_base_path) do
      {:ok, result} -> Repo.rollback({:valid, result})
      {:error, result} -> Repo.rollback({:invalid, result})
    end
  end

  defp transaction_error(reason) do
    %{
      promoted: [],
      removed: [],
      skipped: [],
      errors: [%{path: "transaction", reason: reason}]
    }
  end
end
