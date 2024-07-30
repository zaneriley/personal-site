alias Portfolio.Repo
alias Portfolio.Content.Schemas.CaseStudy
alias Portfolio.Content.Schemas.Note

case_studies = [
  %{
    title: "Case Study 1",
    url: "case-study-1",
    role: "Developer",
    timeline: "2021",
    read_time: 15,
    platforms: ["Web", "Mobile"],
    introduction: "Introduction to Case Study 1",
    file_path: "/files/case-study-1.pdf",
    url: "case-study-1",
    locale: "en",
    content: "Detailed content of Case Study 1",
    company: "Company A",
    sort_order: 1,
    is_draft: false
  },
  %{
    title: "Case Study 2",
    url: "case-study-2",
    role: "Project Manager",
    timeline: "2022",
    read_time: 10,
    platforms: ["Web"],
    introduction: "Introduction to Case Study 2",
    file_path: "/files/case-study-2.pdf",
    url: "case-study-2",
    locale: "en",
    content: "Detailed content of Case Study 2",
    company: "Company B",
    sort_order: 2,
    is_draft: false
  }
]

notes = [
  %{
    title: "Note 1",
    url: "note-1",
    read_time: 5,
    introduction: "Introduction to Note 1",
    file_path: "/files/note-1.md",
    url: "note-1",
    locale: "en",
    content: "Detailed content of Note 1",
    is_draft: false
  },
  %{
    title: "Note 2",
    url: "note-2",
    read_time: 3,
    introduction: "Introduction to Note 2",
    file_path: "/files/note-2.md",
    url: "note-2",
    locale: "en",
    content: "Detailed content of Note 2",
    is_draft: false
  }
]

Enum.each(case_studies, fn case_study ->
  case %CaseStudy{} |> CaseStudy.changeset(case_study) |> Repo.insert() do
    {:ok, inserted} ->
      IO.puts("Inserted case study: #{inserted.title}")

    {:error, changeset} ->
      IO.puts(
        "Failed to insert case study: #{case_study.title}. Errors: #{inspect(changeset.errors)}"
      )
  end
end)

Enum.each(notes, fn note ->
  case %Note{} |> Note.changeset(note) |> Repo.insert() do
    {:ok, inserted} ->
      IO.puts("Inserted note: #{inserted.title}")

    {:error, changeset} ->
      IO.puts(
        "Failed to insert note: #{note.title}. Errors: #{inspect(changeset.errors)}"
      )
  end
end)
