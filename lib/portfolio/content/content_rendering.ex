defmodule Portfolio.ContentRendering do
  @moduledoc """
  Handles the rendering of Markdown case studies into HTML.
  """
  alias Portfolio.Repo
  alias Portfolio.CaseStudy
  require Logger

  def do_render(case_study) do
    case Portfolio.Content.read_markdown_file(case_study) do
      {:ok, markdown_content} ->
        try do
          html_content = Earmark.as_html!(markdown_content)
          Logger.debug("Earmark conversion output: #{inspect(html_content)}")
          Logger.info("Markdown converted to HTML successfully for CaseStudy ID: #{case_study.id}")
          update_case_study_content(case_study, html_content)
        rescue
          exception ->
            Logger.error("Failed to convert markdown to HTML for CaseStudy ID: #{case_study.id}. Exception: #{inspect(exception)}")
            {:error, :conversion_failed}
        end

      {:error, reason} ->
        Logger.error("Markdown rendering failed for CaseStudy ID: #{case_study.id}. Reason: #{reason}")
        {:error, reason}
    end
  end

  defp update_case_study_content(case_study, html_content) do
    Repo.transaction(fn ->
      changeset = CaseStudy.changeset(case_study, %{content: html_content})
      case Repo.update(changeset) do # <--- Add detailed logging here
        {:ok, updated_case_study} ->
          Logger.debug("Case study updated successfully")
          {:ok, updated_case_study}
        {:error, reason} ->
          Logger.error("Case study update failed: #{inspect(reason)}")
          {:error, reason}
      end
    end)
  end
end
