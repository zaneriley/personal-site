defmodule Portfolio.Content do
  @moduledoc """
  A module for managing content in the Portfolio application.

  This module provides functions for managing content in the Portfolio application, including updating case studies from Markdown files, getting all case studies, saving case studies to Markdown files, and getting content with translations.

  ## Usage

  To use the Content module, you can call the `update_case_study_from_file/1` function with a file path as an argument. This function will return a tuple containing the updated case study and the translations.

  For example, to update a case study from a Markdown file at the path "/path/to/file.md", you can use the following code:

      {:ok, case_study} = Content.update_case_study_from_file("/path/to/file.md")

  The `case_study` variable will contain the updated case study.

  ## Case Studies

  Case studies are used to represent individual case studies in the Portfolio application. Each case study is associated with a specific URL and contains metadata, content, and translations.

  """
  alias Portfolio.Content.{FileReader, CaseStudyManager, TranslationManager}
  alias Portfolio.Repo
  alias Portfolio.CaseStudy
  import Ecto.Query, only: [from: 2]
  require Logger

  def update_case_study_from_file(nil) do
    Logger.error("File path is nil")
    {:error, :file_path_missing}
  end

  def update_case_study_from_file(file_path) do
    with {:ok, metadata, markdown} <- FileReader.read_markdown_file(file_path),
         {:ok, locale} <- extract_locale(file_path),
         derived_metadata <-
           Map.merge(metadata, %{file_path: file_path, locale: locale}),
         {:ok, case_study} <-
           CaseStudyManager.get_or_create_case_study(derived_metadata) do
      update_case_study_content(case_study, derived_metadata, markdown, locale)
    else
      error ->
        Logger.error(
          "Case study update (from file) failed. File: #{file_path}. Reason: #{inspect(error)}"
        )

        error
    end
  end

  defp extract_locale(file_path) do
    case Regex.run(~r/case-study\/(\w{2})\//, file_path) do
      [_, locale] -> {:ok, locale}
      _ -> {:error, :invalid_file_path}
    end
  end

  defp update_case_study_content(case_study, metadata, markdown, "en") do
    CaseStudyManager.update_case_study(case_study, metadata, markdown)
  end

  defp update_case_study_content(case_study, metadata, markdown, locale) do
    case TranslationManager.update_or_create_translation(
           case_study,
           locale,
           metadata,
           markdown
         ) do
      translations when is_list(translations) and length(translations) > 0 ->
        {:ok, case_study}

      _ ->
        {:error, :translation_update_failed}
    end
  end

  def get_content_with_translations(content_type, identifier, locale) do
    content_query =
      case content_type do
        :case_study ->
          from c in CaseStudy,
            where: c.url == ^identifier,
            left_join: t in assoc(c, :translations),
            on: t.locale == ^locale,
            preload: [translations: t]
      end

    case Repo.one(content_query) do
      nil ->
        Logger.error("No content found for #{inspect(identifier)}")
        {nil, %{}}

      content ->
        translations = TranslationManager.merge_translations(content, locale)
        {content, translations}
    end
  end

  @page_size 10
  def get_all_case_studies(locale, page_number \\ 1) do
    case_studies_query =
      from c in CaseStudy,
        order_by: [desc: c.sort_order],
        limit: ^@page_size,
        offset: ^((page_number - 1) * @page_size)

    case_studies = Repo.all(case_studies_query)

    Enum.map(case_studies, fn case_study ->
      translations =
        TranslationManager.get_translations(
          case_study,
          CaseStudy.translatable_type(),
          locale
        )

      {case_study, translations}
    end)
  end

  def save_case_studies_to_markdown() do
    case_studies = get_all_case_studies("en", 1)

    for {case_study, _translations} <- case_studies do
      file_path = "priv/case-study/en/#{case_study.url}.md"
      markdown = CaseStudyManager.convert_case_study_to_markdown(case_study)
      File.write!(file_path, markdown)
    end
  end
end
