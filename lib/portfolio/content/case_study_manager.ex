defmodule Portfolio.Content.CaseStudyManager do
  alias Portfolio.Repo
  alias Portfolio.CaseStudy
  require Logger

  def get_or_create_case_study(metadata) do
    Logger.debug(inspect(metadata))
    url = get_in(metadata, [:url])
    case url do
      nil -> {:error, :missing_url_in_metadata}
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

  def update_case_study(case_study, metadata, markdown) do
    fields = CaseStudy.__schema__(:fields)
    filtered_metadata = Map.take(metadata, fields)
    changeset = CaseStudy.changeset(case_study, filtered_metadata)

    Repo.update(changeset)
    |> case do
      {:ok, updated_case_study} ->
        Portfolio.ContentRenderer.do_render(updated_case_study, markdown)
      {:error, reason} ->
        Logger.error("Failed to update case study (ID: #{case_study.id}). Changeset: #{inspect(changeset)}, Reason: #{inspect(reason)}")
        {:error, :case_study_update_failed}
    end
  end

  def convert_case_study_to_markdown(case_study) do
    frontmatter = """
    ---
    title: "#{case_study.title}"
    url: "#{case_study.url}"
    company: "#{case_study.company}"
    role: "#{case_study.role}"
    timeline: "#{case_study.timeline}"
    read_time: #{case_study.read_time}
    platforms: #{inspect(case_study.platforms)}
    sort_order: #{case_study.sort_order}
    introduction: "#{case_study.introduction}"
    ---
    """

    content = case_study.content
    frontmatter <> "\n\n" <> content
  end
end
