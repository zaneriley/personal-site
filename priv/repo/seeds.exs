# Script for populating the database with case study records

alias Portfolio.Repo
alias Portfolio.CaseStudy
alias Portfolio.Translation

case_study =
  Repo.insert!(%CaseStudy{
    title: "Helping people find the healthcare they need",
    url: "helping-people-find-healthcare",
    role: "Lead designer",
    timeline: "Test Timeline",
    read_time: 14,
    platforms: ["Google Search", "Google Maps"],
    introduction:
      "An in-depth look at my experience leading a cross-functional team in developing a product strategy to help people find the local healthcare they need faster and with greater confidence.",
    index: 1,
    file_path: "priv/posts/en/helping-people-find-healthcare-en.md",
    locale: "en"
  })

Repo.insert!(%Translation{
  locale: "ja",
  field_name: "title",
  field_value: "ヘルプする人たちの健康診断をするために",
  translatable_id: case_study.id,
  translatable_type: "CaseStudy"
})

Repo.insert!(%Translation{
  locale: "ja",
  field_name: "role",
  field_value: "デザイナー",
  translatable_id: case_study.id,
  translatable_type: "CaseStudy"
})

Repo.insert!(%Translation{
  locale: "ja",
  field_name: "timeline",
  field_value: "テストのタイムライン",
  translatable_id: case_study.id,
  translatable_type: "CaseStudy"
})

Repo.insert!(%Translation{
  locale: "ja",
  field_name: "read_time",
  field_value: "14",
  translatable_id: case_study.id,
  translatable_type: "CaseStudy"
})

Repo.insert!(%Translation{
  locale: "ja",
  field_name: "platforms",
  field_value: "Google Search, Google Maps",
  translatable_id: case_study.id,
  translatable_type: "CaseStudy"
})

Repo.insert!(%Translation{
  locale: "ja",
  field_name: "introduction",
  field_value: "私たちのクロスファクタリングチームが、人々がローカルの健康診断をするために、プロダクトストラテジーを開発している。",
  translatable_id: case_study.id,
  translatable_type: "CaseStudy"
})
