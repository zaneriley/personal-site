defmodule Portfolio.ContentTest do
  use Portfolio.DataCase, async: true
  alias Portfolio.Content

  describe "get_case_study_by_title/1" do
    test "returns the case study with the given title" do
      case_study = insert(:case_study, title: "Test Title")
      assert Content.get_case_study_by_title("Test Title") == case_study
    end

    test "returns nil if no case study is found" do
      assert is_nil(Content.get_case_study_by_title("Nonexistent Title"))
    end
  end
end
