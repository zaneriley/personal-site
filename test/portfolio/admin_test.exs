defmodule Portfolio.AdminTest do
  use Portfolio.DataCase

  alias Portfolio.Admin

  describe "case_studies" do
    alias Portfolio.Admin.CaseStudy

    import Portfolio.AdminFixtures

    @invalid_attrs %{
      title: nil,
      url: nil,
      role: nil,
      timeline: nil,
      read_time: nil,
      platforms: nil,
      introduction: nil,
      content: nil
    }

    test "list_case_studies/0 returns all case_studies" do
      case_study = case_study_fixture()
      assert Admin.list_case_studies() == [case_study]
    end

    test "get_case_study!/1 returns the case_study with given id" do
      case_study = case_study_fixture()
      assert Admin.get_case_study!(case_study.id) == case_study
    end

    test "create_case_study/1 with valid data creates a case_study" do
      valid_attrs = %{
        title: "some title",
        url: "some url",
        role: "some role",
        timeline: "some timeline",
        read_time: 42,
        platforms: ["option1", "option2"],
        introduction: "some introduction",
        content: "some content"
      }

      assert {:ok, %Portfolio.CaseStudy{} = case_study} =
        Admin.create_case_study(valid_attrs)

      assert case_study.title == "some title"
      assert case_study.url == "some url"
      assert case_study.role == "some role"
      assert case_study.timeline == "some timeline"
      assert case_study.read_time == 42
      assert case_study.platforms == ["option1", "option2"]
      assert case_study.introduction == "some introduction"
      assert case_study.content == "some content"
    end

    test "create_case_study/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Admin.create_case_study(@invalid_attrs)
    end

    test "update_case_study/2 with valid data updates the case_study" do
      case_study = case_study_fixture()

      update_attrs = %{
        title: "some updated title",
        url: "some updated url",
        role: "some updated role",
        timeline: "some updated timeline",
        read_time: 43,
        platforms: ["option1"],
        introduction: "some updated introduction",
        content: "some updated content"
      }

      assert {:ok, %Portfolio.CaseStudy{} = case_study} =
        Admin.update_case_study(case_study, update_attrs)

      assert case_study.title == "some updated title"
      assert case_study.url == "some updated url"
      assert case_study.role == "some updated role"
      assert case_study.timeline == "some updated timeline"
      assert case_study.read_time == 43
      assert case_study.platforms == ["option1"]
      assert case_study.introduction == "some updated introduction"
      assert case_study.content == "some updated content"
    end

    test "update_case_study/2 with invalid data returns error changeset" do
      case_study = case_study_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Admin.update_case_study(case_study, @invalid_attrs)

      assert case_study == Admin.get_case_study!(case_study.id)
    end

    test "delete_case_study/1 deletes the case_study" do
      case_study = case_study_fixture()
      assert {:ok, %Portfolio.CaseStudy{}} = Admin.delete_case_study(case_study)

      assert_raise Ecto.NoResultsError, fn ->
        Admin.get_case_study!(case_study.id)
      end
    end

    test "change_case_study/1 returns a case_study changeset" do
      case_study = case_study_fixture()
      assert %Ecto.Changeset{} = Admin.change_case_study(case_study)
    end
  end
end
