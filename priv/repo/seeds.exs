alias Portfolio.Repo
alias Portfolio.CaseStudy

case_studies = [
  %CaseStudy{
    title: "Case Study 1",
    url: "case-study-1",
    role: "Developer",
    timeline: "2021",
    read_time: 15,
    platforms: ["Web", "Mobile"],
    introduction: "Introduction to Case Study 1",
    file_path: "/files/case_study_1.pdf",
    locale: "en",
    content: "Detailed content of Case Study 1",
    company: "Company A",
    sort_order: 1
  },
  %CaseStudy{
    title: "Case Study 2",
    url: "case-study-2",
    role: "Project Manager",
    timeline: "2022",
    read_time: 10,
    platforms: ["Web"],
    introduction: "Introduction to Case Study 2",
    file_path: "/files/case_study_2.pdf",
    locale: "en",
    content: "Detailed content of Case Study 2",
    company: "Company B",
    sort_order: 2
  }
]

Enum.each(case_studies, fn cs ->
  Repo.insert!(cs)
end)
