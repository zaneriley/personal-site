defmodule Portfolio.Content do
  alias Portfolio.Repo
  alias Portfolio.CaseStudy
  alias Portfolio.Translation
  import Ecto.Query, only: [from: 2]  # Import the `from/2` function from Ecto.Query
  require Logger

  @page_size 10  # You can set this to what makes sense for your application


  # Function to fetch content and its translations
  def get_content_with_translations(content_type, identifier, locale) do
    content_query =
      case content_type do
        :case_study ->
          from c in CaseStudy, where: c.url == ^identifier
        # Add clauses for other content types (e.g., :note)
      end

    # Fetch the content
    content = Repo.one(content_query)

    # Proceed only if content is found
    if content do
      # Construct the query for translations
      translation_query =
        from t in Translation,
          where: t.translatable_id == ^content.id and
                 t.translatable_type == ^Atom.to_string(content_type) and
                 t.locale == ^locale

      # Fetch translations based on the constructed query
      translations =
        Repo.all(translation_query)
        |> Enum.into(%{}, fn t -> {t.field_name, t.field_value} end)

      {content, translations}
    else
      {nil, %{}}
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
          where: t.translatable_id == ^case_study.id and
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
