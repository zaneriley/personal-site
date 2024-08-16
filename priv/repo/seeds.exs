alias Portfolio.Repo
alias Portfolio.Content.Schemas.CaseStudy
alias Portfolio.Content.Schemas.Note
alias Portfolio.Content.MarkdownRendering.CustomParser

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
    locale: "en",
    content: "# this ia a case study",
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
    locale: "en",
    content: "# this ia a case study",
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
    locale: "en",
    content: "# this ia a note",
    is_draft: false
  },
  %{
    title: "Note 2",
    url: "note-2",
    read_time: 3,
    introduction: "Introduction to Note 2",
    file_path: "/files/note-2.md",
    locale: "en",
    content: "# this ia a note",
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
