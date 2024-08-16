defmodule Portfolio.ContentFixtures do
  @moduledoc """
  Provides fixture functions for creating test data related to content entities.
  Includes functions for generating Note and CaseStudy fixtures with realistic default attributes.
  """
  alias Portfolio.Repo
  alias Portfolio.Content.Schemas.{Note, CaseStudy}
  alias Portfolio.Content.Schemas.Translation
  alias Portfolio.Content.TranslatableFields
  require Logger

  @doc """
  Creates a note with dynamic and realistic default attributes that can be overridden.
  """
  def note_fixture(attrs \\ %{}, opts \\ []) do
    sequence = System.unique_integer([:positive])

    default_attrs = %{
      "title" => "Insightful Note #{sequence}",
      "content" =>
        "Content for note #{sequence} with insightful analysis and detailed information.",
      "locale" => "en",
      "url" => "insightful-note-#{sequence}",
      "introduction" => "Introduction for note #{sequence}",
      "read_time" => 5 + rem(sequence, 10),
      "file_path" => "priv/content/notes/note_#{sequence}.md",
      "published_at" => ~N[2023-01-01 00:00:00],
      "is_draft" => false
    }

    string_attrs = for {key, val} <- attrs, into: %{}, do: {to_string(key), val}

    note =
      %Note{}
      |> Note.changeset(Map.merge(default_attrs, string_attrs))
      |> Repo.insert!()

    unless opts[:skip_translations] do
      translation_fixture(note, "ja")
    end

    note
  end

  @doc """
  Creates a case study with dynamic and realistic default attributes that can be overridden.
  """
  def case_study_fixture(attrs \\ %{}, opts \\ []) do
    Logger.debug("Creating case study fixture")

    sequence = System.unique_integer([:positive])

    default_attrs = %{
      "title" => "Case Study #{sequence}",
      "content" =>
        "Detailed exploration of case study #{sequence}, covering all aspects of the project.",
      "locale" => "en",
      "url" => "case-study-#{sequence}",
      "company" => "Company #{sequence}",
      "role" => "Role #{sequence}",
      "timeline" => "2020 - #{2020 + rem(sequence, 10)}",
      "platforms" => ["Web", "Mobile"],
      "sort_order" => sequence,
      "introduction" => "Introduction for case study #{sequence}",
      "read_time" => 5 + rem(sequence, 10),
      "file_path" => "priv/content/case_studies/case_study_#{sequence}.md",
      "published_at" => ~N[2023-01-01 00:00:00],
      "is_draft" => false
    }

    string_attrs = for {key, val} <- attrs, into: %{}, do: {to_string(key), val}

    case_study =
      %CaseStudy{}
      |> CaseStudy.changeset(Map.merge(default_attrs, string_attrs))
      |> Repo.insert!()

    if opts[:translations] do
      Enum.each(opts[:translations], fn {locale, trans_attrs} ->
        translation_fixture(case_study, locale, trans_attrs)
      end)
    end

    Logger.debug("Case study created: #{inspect(case_study)}")

    case_study
  end

  def translation_fixture(content, locale, attrs \\ %{}) do
    translatable_fields =
      TranslatableFields.translatable_fields(content.__struct__)

    default_attrs =
      Enum.reduce(translatable_fields, %{}, fn field, acc ->
        Map.put(
          acc,
          Atom.to_string(field),
          "#{locale} translation for #{field}"
        )
      end)

    merged_attrs = Map.merge(default_attrs, attrs)

    Enum.map(merged_attrs, fn {field, value} ->
      %Translation{}
      |> Translation.changeset(%{
        translatable_id: content.id,
        translatable_type: content.__struct__.translatable_type(),
        locale: locale,
        field_name: to_string(field),
        field_value: value
      })
      |> Repo.insert!()
    end)
  end
end
