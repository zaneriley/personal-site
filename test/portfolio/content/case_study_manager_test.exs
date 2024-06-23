defmodule Portfolio.Content.CaseStudyManagerTest do
  use ExUnit.Case, async: true
  use Portfolio.DataCase

  alias Portfolio.Content.CaseStudyManager
  import Portfolio.AdminFixtures

  describe "get_or_create_case_study/1" do
    test "creates a new case study when it doesn't exist" do
      attrs = %{url: "new-case-study-#{System.unique_integer([:positive])}"}
      metadata = case_study_fixture(attrs) |> Map.from_struct()

      assert {:ok, case_study} = CaseStudyManager.get_or_create_case_study(metadata)
      assert case_study.url == metadata.url
    end

    test "returns existing case study when it already exists" do
      existing_case_study = case_study_fixture()
      metadata = existing_case_study |> Map.from_struct()

      assert {:ok, case_study} = CaseStudyManager.get_or_create_case_study(metadata)
      assert case_study.id == existing_case_study.id
      assert case_study.url == existing_case_study.url
    end
  end
end
