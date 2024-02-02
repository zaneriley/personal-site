# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Portfolio.Repo.insert!(%Portfolio.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Portfolio.Repo
alias Portfolio.CaseStudy

Repo.insert!(%CaseStudy{
  title: "Helping people find the healthcare they need",
  url: "helping-people-find-healthcare",
  role: "Lead designer",
  timeline: "Test Timeline",
  read_time: 14,
  platforms: ["Google Search, Google Maps"],
  introduction:
    "An in-depth look at my experience leading a cross-functional team in developing a product strategy to help people find the local healthcare they need faster and with greater confidence."
})
