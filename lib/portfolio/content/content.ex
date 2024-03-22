defmodule Portfolio.Content do
  @moduledoc """
  Provides a centralized access point for retrieving content and its translations.

  The Content module encapsulates the logic for:
  - Fetching a single content item, such as a case study, along with its translations for a given locale using `get_content_with_translations/3`.
  - Retrieving all case studies in a paginated format with their respective translations through `get_all_case_studies/2`.

  These functions abstract the complexities of joining content with their translations and present a simplified interface for the rest of the application to consume content in a locale-aware manner.
  """
  alias Portfolio.Repo
  alias Portfolio.CaseStudy
  alias Portfolio.Translation
  alias Portfolio.ContentRendering
  import Ecto.Query, only: [from: 2]
  require Logger

  @doc """
  Reads a Markdown file and extracts its frontmatter and content.
  It returns a tuple with the frontmatter and content.

  ## Examples

      iex> Portfolio.Content.read_markdown_file("path/to/file.md")
      {:ok, %{"title" => "My Case Study", "url" => "my-case-study"}, "My Markdown Content"}
  """
def read_markdown_file(file_path) do
  with {:ok, file_content} <- File.read(file_path),
       {:ok, metadata} <- extract_frontmatter(file_content),
       {:ok, markdown} <- Portfolio.ContentRendering.extract_markdown(file_content) do
    {:ok, metadata, markdown}
  else
    {:error, :file_path_missing} -> # When File.read returns {:error, nil}
      Logger.error("File path is nil")
      {:error, :file_path_missing}

    {:error, reason} ->
      Logger.error("Error extracting content from file #{file_path}. Reason: #{reason}")
      {:error, reason}
  end
end


  @doc """
  Separates a markdown file into its frontmatter and content.

  ## Examples

      iex> Portfolio.Content.extract_frontmatter("title: My Case Study\nurl: my-case-study\n---\nMy Markdown Content")
      {:ok, %{"title" => "My Case Study", "url" => "my-case-study"}}
  """
  def extract_frontmatter(file_content) do
    case String.split(file_content, "---", parts: 3) do
      [_, frontmatter, _rest] ->
        case :yamerl_constr.string(frontmatter) do
          [metadata] ->
            Logger.debug("Parsed frontmatter without conversions: #{inspect(metadata)}")

            metadata = Enum.into(metadata, %{}, fn
              {charlist_key, charlist_value} when is_list(charlist_key) and is_list(charlist_value) ->
                key = String.to_existing_atom(List.to_string(charlist_key))
                value = if is_list(List.first(charlist_value)), do: Enum.map(charlist_value, &List.to_string/1), else: List.to_string(charlist_value)
                {key, value}

              {key, charlist_value} when is_list(charlist_value) ->
                {key, List.to_string(charlist_value)}

              {charlist_key, value} when is_list(charlist_key) ->
                {String.to_existing_atom(List.to_string(charlist_key)), value}

              {key, value} ->
                {key, value}
            end)
            {:ok, metadata}
          error ->
            Logger.error("YAML parsing failed. Frontmatter: #{frontmatter}, Error: #{inspect(error)}")
            {:error, {:yaml_parsing_failed, error}}
        end

      _ ->
        {:error, :missing_frontmatter_delimiters}
    end
  end

  def update_case_study_from_file(file_path) do
    with {:ok, metadata, markdown} <- Portfolio.Content.read_markdown_file(file_path),
         {:ok, case_study} <- get_or_create_case_study(metadata) do
      update_case_study(case_study, metadata, markdown)
    else
      {:error, :file_processing_failed} ->
        Logger.error("Failed to process case study file: #{file_path}")
        {:error, :file_processing_failed}

      {:error, reason} ->
        Logger.error("Case study update (from file) failed. File: #{file_path}. \nReason: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_or_create_case_study(metadata) do
    Logger.debug(inspect(metadata))

    url = get_in(metadata, [:url])

    case url do
      nil ->
        {:error, :missing_url_in_metadata}
      url ->
        case Repo.get_by(CaseStudy, url: url) do
          nil -> create_case_study(metadata)
          case_study -> {:ok, case_study}
        end
    end
  end


  defp create_case_study(metadata) do
    %CaseStudy{}
    |> CaseStudy.changeset(metadata)
    |> Repo.insert()
    |> case do
        {:ok, case_study} -> {:ok, case_study}
        {:error, reason} ->
          Logger.error("Failed to create case study. Metadata: #{inspect(metadata)}, Reason: #{inspect(reason)}")
          {:error, :case_study_creation_failed}
    end
  end


  defp update_case_study(case_study, metadata, markdown) do
    changeset = CaseStudy.changeset(case_study, metadata)
    Repo.update(changeset)
    |> case do
      {:ok, updated_case_study} ->
        Portfolio.ContentRendering.do_render(updated_case_study, markdown)
      {:error, reason} ->
        Logger.error("Failed to update case study (ID: #{case_study.id}). Changeset: #{inspect(changeset)}, Reason: #{inspect(reason)}")
        {:error, :case_study_update_failed}
    end
  end



  def get_content_with_translations(content_type, identifier, locale) do
    Logger.debug("get_content_with_translations/3 called with #{inspect(content_type)}, #{inspect(identifier)}, #{inspect(locale)}")
    content_query =
      case content_type do
        :case_study ->
          from c in CaseStudy, where: c.url == ^identifier
          # Add clauses for other content types (e.g., :note)
      end

    content = Repo.one(content_query)
    Logger.debug("Content fetched: #{inspect(content)}")

    if content do
      translation_query =
        from t in Translation,
          where:
            t.translatable_id == ^content.id and
              t.translatable_type == ^Atom.to_string(content_type) and
              t.locale == ^locale

      translations =
        Repo.all(translation_query)
        |> Enum.into(%{}, fn t -> {t.field_name, t.field_value} end)
      Logger.debug("Translations fetched: #{inspect(translations)}")

      Logger.debug("Content after attempting to update :content field: #{inspect(content)}")

      {content, translations}
    else
      Logger.error("No content found for #{inspect(identifier)}")

      {nil, %{}}
    end
  end

  @page_size 10
  def get_all_case_studies(locale, page_number \\ 1) do
    case_studies_query =
      from c in CaseStudy,
        order_by: [desc: c.inserted_at],
        limit: ^@page_size,
        offset: ^((page_number - 1) * @page_size)

    case_studies = Repo.all(case_studies_query)

    Enum.map(case_studies, fn case_study ->
      Logger.debug("Fetching translations for CaseStudy ID: #{case_study.id}")

      translation_query =
        from t in Translation,
          where:
            t.translatable_id == ^case_study.id and
              t.translatable_type == ^"CaseStudy" and
              t.locale == ^locale

      Logger.debug("Translation Query: #{inspect(translation_query)}")

      translations =
        Repo.all(translation_query)
        |> Enum.into(%{}, fn t -> {t.field_name, t.field_value} end)

      {case_study, translations}
    end)
  end


end
