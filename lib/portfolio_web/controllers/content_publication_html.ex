defmodule PortfolioWeb.ContentPublicationHTML do
  @moduledoc false

  use PortfolioWeb, :html

  alias Portfolio.Content.Schemas.PublicationLedgerEntry

  embed_templates "content_publication_html/*"

  @spec path_errors(PublicationLedgerEntry.t()) :: [map()]
  def path_errors(%PublicationLedgerEntry{
        structured_errors: %{"errors" => errors}
      })
      when is_list(errors) do
    errors
  end

  def path_errors(%PublicationLedgerEntry{structured_errors: structured_errors})
      when structured_errors == %{} do
    []
  end

  @spec path_list(PublicationLedgerEntry.t(), atom()) :: [String.t()]
  def path_list(%PublicationLedgerEntry{promoted_paths: paths}, :promoted_paths)
      when is_list(paths) do
    paths
  end

  def path_list(%PublicationLedgerEntry{removed_paths: paths}, :removed_paths)
      when is_list(paths) do
    paths
  end

  def path_list(%PublicationLedgerEntry{skipped_paths: paths}, :skipped_paths)
      when is_list(paths) do
    paths
  end

  @spec error_path(map()) :: String.t()
  def error_path(%{"path" => path}) when is_binary(path), do: path

  @spec error_reason(map()) :: String.t()
  def error_reason(%{"reason" => reason}) when is_binary(reason), do: reason
end
