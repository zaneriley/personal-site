defmodule Portfolio.AdminFixtures do
  alias Portfolio.Content.TranslationManager
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Portfolio.Admin` context.
  """

  @doc """
  Generate a case_study.
  """
  def case_study_fixture(attrs \\ %{}) do
    include_translations = Map.get(attrs, :include_translations, false)
    attrs = Map.drop(attrs, [:include_translations])

    sequence = System.unique_integer([:positive])

    default_attrs = %{
      title: "Case Study #{sequence}",
      url: "case-study-#{sequence}",
      company: "TechCorp Solutions",
      role: "Senior Software Engineer",
      timeline: "January 2022 - June 2022",
      read_time: 5 + rem(sequence, 10),  # 5-14 minutes
      platforms: ["Web", "Mobile", "Cloud"],
      introduction: "Revolutionizing inventory management for a global e-commerce platform.",
      content: "TechCorp Solutions faced significant challenges with their legacy inventory system...",
      sort_order: sequence * 10,
      file_path: "priv/case_studies/case_study_#{sequence}.md",
      locale: "en"
    }

    merged_attrs = Map.merge(default_attrs, attrs)

    {:ok, case_study} = Portfolio.Admin.create_case_study(merged_attrs)

    if include_translations do
      ja_translations = %{
        title: "グローバルEコマース在庫管理システムの革新",
        role: "シニアソフトウェアエンジニア",
        company: "テックコープソリューションズ",
        introduction: "世界的なEコマースプラットフォームの在庫管理を革新し、効率を劇的に向上させました。",
        timeline: "2022年1月 - 2022年6月"
      }
      ja_content = "テックコープソリューションズは、レガシーな在庫システムに大きな課題を抱えていました。..."

      TranslationManager.update_or_create_translation(case_study, "ja", ja_translations, ja_content)

      Portfolio.Repo.preload(case_study, :translations)
    end

    case_study
  end
end
