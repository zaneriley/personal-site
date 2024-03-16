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
  import Ecto.Query, only: [from: 2]
  require Logger

  def create_case_study(attrs) do
    %CaseStudy{}
    |> CaseStudy.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, case_study} -> Portfolio.ContentRendering.do_render(case_study)
      {:error, reason}   -> {:error, reason}
    end
  end

  def change_case_study(case_study) do
    changeset = CaseStudy.changeset(case_study, %{})

    case Repo.update(changeset) do
      {:ok, case_study} -> Portfolio.ContentRendering.do_render(case_study)
      {:error, reason}   -> {:error, reason}
    end
  end

  @page_size 10

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

  def read_markdown_file(case_study) do
    case case_study.file_path do
      nil ->
        Logger.error("File path is nil for case study: #{case_study.title}")
        {:error, "File path is nil."}
      file_path ->
        Logger.debug("Reading markdown file: #{file_path}")
        case File.read(file_path) do
          {:ok, file_content} -> {:ok, file_content}
          {:error, reason} ->
            Logger.error("Failed to read file: #{file_path} with reason: #{reason}")
            {:error, "Could not read file"}
        end
    end
  end

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
