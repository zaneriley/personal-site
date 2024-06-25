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
      with {:ok, metadata, markdown} <-
             FileReader.read_markdown_file(file_path),
           [_, locale] <- Regex.run(~r/case-study\/(\w{2})\//, file_path),
           derived_metadata =
             Map.merge(metadata, %{file_path: file_path, locale: locale}),
           {:ok, case_study} <-
             CaseStudyManager.get_or_create_case_study(derived_metadata) do
        if locale == "en" do
          CaseStudyManager.update_case_study(
            case_study,
            derived_metadata,
            markdown
          )
        else
          case TranslationManager.update_or_create_translation(
                 case_study,
                 locale,
                 derived_metadata,
                 markdown
               ) do
            translations
            when is_list(translations) and length(translations) > 0 ->
              {:ok, case_study}

            _ ->
              {:error, :translation_update_failed}
          end
        end
      else
        error ->
          Logger.error(
            "Case study update (from file) failed. File: #{file_path}. Reason: #{inspect(error)}"
          )

          error
      end
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
