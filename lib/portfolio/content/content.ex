defmodule Portfolio.Content do
  alias Portfolio.Content.{FileReader, CaseStudyManager, TranslationManager}
  alias Portfolio.Repo
  alias Portfolio.CaseStudy
  import Ecto.Query, only: [from: 2]
  require Logger

  def update_case_study_from_file(file_path) do
    if is_nil(file_path) do
      Logger.error("File path is nil")
      {:error, :file_path_missing}
    else
      with {:ok, metadata, markdown} <- FileReader.read_markdown_file(file_path),
           [_, locale] <- Regex.run(~r/case-study\/(\w{2})\//, file_path),
           derived_metadata = Map.merge(metadata, %{file_path: file_path, locale: locale}),
           {:ok, case_study} <- CaseStudyManager.get_or_create_case_study(derived_metadata) do
        CaseStudyManager.update_case_study(case_study, derived_metadata, markdown)
        TranslationManager.update_or_create_translation(case_study, locale, markdown)
      else
        {:error, :file_path_missing} ->
          Logger.error("File path is missing for: #{file_path}")
          {:error, :file_path_missing}
        {:error, :file_processing_failed} ->
          Logger.error("Failed to process case study file: #{file_path}")
          {:error, :file_processing_failed}
        {:error, reason} ->
          Logger.error("Case study update (from file) failed. File: #{file_path}. Reason: #{inspect(reason)}")
          {:error, reason}
      end
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

    if content do
      translations = TranslationManager.get_translations(content, content_type, locale)
      Logger.debug("Translations fetched: #{inspect(translations)}")
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
        order_by: [desc: c.sort_order],
        limit: ^@page_size,
        offset: ^((page_number - 1) * @page_size)

    case_studies = Repo.all(case_studies_query)

    Enum.map(case_studies, fn case_study ->
      translations = TranslationManager.get_translations(case_study, :case_study, locale)
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
