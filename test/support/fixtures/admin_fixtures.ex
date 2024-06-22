defmodule Portfolio.AdminFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Portfolio.Admin` context.
  """

  @doc """
  Generate a case_study.
  """
  def case_study_fixture(attrs \\ %{}) do
    {:ok, case_study} =
      attrs
      |> Enum.into(%{
        content: "some content",
        company: "some company",
        locale: "en",
        file_path: "priv/en/some-file-path.md",
        introduction: "some introduction",
        platforms: ["option1", "option2"],
        read_time: 42,
        role: "some role",
        timeline: "some timeline",
        title: "some title",
        url: "some url",
        sort_order: 1000
      })
      |> Portfolio.Admin.create_case_study()

    case_study
  end
end
