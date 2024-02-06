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
        introduction: "some introduction",
        platforms: ["option1", "option2"],
        read_time: 42,
        role: "some role",
        timeline: "some timeline",
        title: "some title",
        url: "some url"
      })
      |> Portfolio.Admin.create_case_study()

    case_study
  end
end
