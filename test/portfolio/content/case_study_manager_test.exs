defmodule Portfolio.Content.CaseStudyManagerTest do
  use ExUnit.Case, async: true
  use Portfolio.DataCase
  alias Portfolio.Content.CaseStudyManager
  import Portfolio.AdminFixtures

  describe "get_or_create_case_study/1" do
    test "creates a new case study when it doesn't exist" do
      metadata = %{url: "new-case-study", title: "New Case Study"}
      assert {:ok, case_study} = CaseStudyManager.get_or_create_case_study(metadata)
      assert case_study.url == "new-case-study"
    end

    test "returns existing case study when it exists" do
      existing_case_study = case_study_fixture()
      metadata = %{url: existing_case_study.url}
      assert {:ok, case_study} = CaseStudyManager.get_or_create_case_study(metadata)
      assert case_study.id == existing_case_study.id
    end
  end
end
