alias Portfolio.Repo
alias Portfolio.Content.Schemas.Project
alias Portfolio.Content.Schemas.Note
alias Portfolio.Content.MarkdownRendering.CustomParser

projects = [
  %{
    title: "Project 1",
    url: "project-1",
    role: "Developer",
    timeline: "2021",
    read_time: 15,
    platforms: ["Web", "Mobile"],
    introduction: "Introduction to Project 1",
    file_path: "/content/work/test-project/en.md",
    locale: "en",
    content: "# this ia a project",
    company: "Company A",
    sort_order: 1,
    is_draft: false,
    published_at: NaiveDateTime.utc_now()
  },
  %{
    title: "Project 2",
    url: "project-2",
    role: "Project Manager",
    timeline: "2022",
    read_time: 10,
    platforms: ["Web"],
    introduction: "Introduction to Project 2",
    file_path: "/content/work/test-project/en.md",
    locale: "en",
    content: "# this ia a project",
    company: "Company B",
    sort_order: 2,
    is_draft: false,
    published_at: NaiveDateTime.utc_now()
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
    is_draft: false,
    published_at: NaiveDateTime.utc_now()
  },
  %{
    title: "Note 2",
    url: "note-2",
    read_time: 3,
    introduction: "Introduction to Note 2",
    file_path: "/files/note-2.md",
    locale: "en",
    content: "# this ia a note",
    is_draft: false,
    published_at: NaiveDateTime.utc_now()
  }
]

Enum.each(projects, fn project ->
  case %Project{} |> Project.changeset(project) |> Repo.insert() do
    {:ok, inserted} ->
      IO.puts("Inserted project: #{inserted.title}")

    {:error, changeset} ->
      IO.puts(
        "Failed to insert project: #{project.title}. Errors: #{inspect(changeset.errors)}"
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
