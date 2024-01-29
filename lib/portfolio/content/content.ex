defmodule Portfolio.Content do
  alias Portfolio.Repo
  alias Portfolio.CaseStudy

  def list_case_studies do
    Repo.all(CaseStudy)
  end

  def get_case_study!(id), do: Repo.get!(CaseStudy, id)

  def get_case_study_by_url(url) do
    Repo.get_by(CaseStudy, url: url)
  end

  # Other functions for creating, updating, deleting case studies
end
