defmodule PortfolioWeb.ContentPublicationHTML do
  @moduledoc false

  use PortfolioWeb, :html

  alias Portfolio.Content.Schemas.PublicationLedgerEntry

  embed_templates "content_publication_html/*"

  @spec path_errors(PublicationLedgerEntry.t()) :: [map()]
  def path_errors(%PublicationLedgerEntry{structured_errors: structured_errors}) do
    case structured_errors do
      %{"errors" => errors} when is_list(errors) -> errors
      _structured_errors -> []
    end
  end

  @spec path_list(PublicationLedgerEntry.t(), atom()) :: [String.t()]
  def path_list(%PublicationLedgerEntry{} = entry, field)
      when field in [:promoted_paths, :removed_paths, :skipped_paths] do
    Map.get(entry, field, [])
  end

  @spec error_path(map()) :: String.t()
  def error_path(%{"path" => path}) when is_binary(path), do: path
  def error_path(_error), do: "unknown path"

  @spec error_reason(map()) :: String.t()
  def error_reason(%{"reason" => reason}) when is_binary(reason), do: reason
  def error_reason(_error), do: "unknown reason"
end
