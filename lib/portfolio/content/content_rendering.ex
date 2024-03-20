defmodule Portfolio.ContentRendering do
  @moduledoc """
  Handles the rendering of Markdown case studies into HTML and provides
  support for extracting Markdown content from files.

  Key responsibilities include:

  * **Markdown to HTML Conversion:** Core function `do_render/1` takes a
    `case_study` struct and a `markdown` string as input, and returns a
    rendered HTML string.
  * **Markdown Extraction:** The `extract_markdown/1` function is responsible
    for extracting Markdown content from a file. It splits the file content
    into three parts separated by three dashes (`---`), and returns the
    second part, which contains the Markdown content.
  """
  alias Portfolio.Repo
  alias Portfolio.CaseStudy
  require Logger

  def extract_markdown(file_content) do
    case String.split(file_content, "---", parts: 3) do
      [_, _, markdown] -> {:ok, markdown}
      _ -> {:error, :no_markdown_content}
    end
  end

  def do_render(case_study) do
    with {:ok, markdown_content} <- Portfolio.Content.read_markdown_file(case_study),
         {:ok, html_content} <- Earmark.as_html!(markdown_content),
         {:ok, updated_case_study} <- update_case_study_content(case_study, html_content) do
       {:ok, updated_case_study}
    else
      {:error, :file_processing_failed} ->
        Logger.error("Markdown rendering failed for CaseStudy ID (file): #{case_study.id}")
        {:error, :file_processing_failed}

      {:error, :conversion_failed} ->
        Logger.error("Failed to convert markdown to HTML for CaseStudy ID: #{case_study.id}")
        {:error, :conversion_failed}

      {:error, reason} ->
        Logger.error("Markdown rendering failed for CaseStudy ID (unknown error): #{case_study.id}. Reason: #{reason}")
        {:error, reason}
    end

  end
  # def do_render(case_study) do
  #   case Portfolio.Content.read_markdown_file(case_study) do
  #     {:ok, markdown_content} ->
  #       try do
  #         html_content = Earmark.as_html!(markdown_content)
  #         Logger.debug("Earmark conversion output: #{inspect(html_content)}")
  #         Logger.info("Markdown converted to HTML successfully for CaseStudy ID: #{case_study.id}")
  #         update_case_study_content(case_study, html_content)
  #       rescue
  #         exception ->
  #           Logger.error("Failed to convert markdown to HTML for CaseStudy ID: #{case_study.id}. Exception: #{inspect(exception)}")
  #           {:error, :conversion_failed}
  #       end

  #     {:error, reason} ->
  #       Logger.error("Markdown rendering failed for CaseStudy ID: #{case_study.id}. Reason: #{reason}")
  #       {:error, reason}
  #   end
  # end

  defp update_case_study_content(case_study, html_content) do
    Repo.transaction(fn ->
      changeset = CaseStudy.changeset(case_study, %{content: html_content})
      case Repo.update(changeset) do
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
