defmodule Portfolio.ContentFixtures do
  @moduledoc """
  Provides fixture functions for creating test data related to content entities.
  Includes functions for generating Note and Project fixtures with realistic default attributes.
  """
  alias Portfolio.Content.Publishing
  alias Portfolio.Content.Schemas.Project
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Content.Schemas.Translation
  alias Portfolio.Content.TranslatableFields
  alias Portfolio.Repo

  require Logger

  @doc """
  Creates a note with dynamic and realistic default attributes that can be overridden.
  """
  def note_fixture(attrs \\ %{}, opts \\ []) do
    sequence = System.unique_integer([:positive])

    {publication_generation_id, content_sha, accept_generation?} =
      fixture_publication_generation(opts)

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
      %Note{publication_generation_id: publication_generation_id}
      |> Note.changeset(Map.merge(default_attrs, string_attrs))
      |> Repo.insert!()

    maybe_accept_fixture_generation(
      note,
      publication_generation_id,
      content_sha,
      accept_generation?
    )

    unless opts[:skip_translations] do
      translation_fixture(note, "ja")
    end

    note
  end

  @doc """
  Creates a project with dynamic and realistic default attributes that can be overridden.
  """
  def project_fixture(attrs \\ %{}, opts \\ []) do
    Logger.debug("Creating project fixture")

    sequence = System.unique_integer([:positive])

    {publication_generation_id, content_sha, accept_generation?} =
      fixture_publication_generation(opts)

    default_attrs = %{
      "title" => "Project #{sequence}",
      "content" =>
        "Detailed exploration of project #{sequence}, covering all aspects of the project.",
      "locale" => "en",
      "url" => "project-#{sequence}",
      "company" => "Company #{sequence}",
      "role" => "Role #{sequence}",
      "timeline" => "2020 - #{2020 + rem(sequence, 10)}",
      "platforms" => ["Web", "Mobile"],
      "sort_order" => sequence,
      "introduction" => "Introduction for project #{sequence}",
      "read_time" => 5 + rem(sequence, 10),
      "file_path" => "priv/content/projects/project_#{sequence}.md",
      "published_at" => ~N[2023-01-01 00:00:00],
      "is_draft" => false
    }

    string_attrs = for {key, val} <- attrs, into: %{}, do: {to_string(key), val}

    project =
      %Project{publication_generation_id: publication_generation_id}
      |> Project.changeset(Map.merge(default_attrs, string_attrs))
      |> Repo.insert!()

    maybe_accept_fixture_generation(
      project,
      publication_generation_id,
      content_sha,
      accept_generation?
    )

    if opts[:translations] do
      Enum.each(opts[:translations], fn {locale, trans_attrs} ->
        translation_fixture(project, locale, trans_attrs)
      end)
    end

    Logger.debug("Project created: #{inspect(project)}")

    project
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

  defp fixture_publication_generation(opts) do
    case Keyword.fetch(opts, :publication_generation_id) do
      {:ok, generation_id} ->
        {generation_id, nil, false}

      :error ->
        existing_or_new_fixture_publication_generation()
    end
  end

  defp existing_or_new_fixture_publication_generation do
    case Publishing.get_publication_state() do
      %{live_content_publication_generation_id: generation_id}
      when is_binary(generation_id) ->
        {generation_id, nil, false}

      _ ->
        content_sha = String.duplicate("f", 40)

        {:ok, generation} =
          Publishing.prepare_generation(content_sha, source: :bootstrap)

        {generation.id, content_sha, true}
    end
  end

  defp maybe_accept_fixture_generation(
         _content,
         _generation_id,
         _content_sha,
         false
       ) do
    :ok
  end

  defp maybe_accept_fixture_generation(
         %{is_draft: false, published_at: published_at},
         generation_id,
         content_sha,
         true
       )
       when not is_nil(published_at) do
    {:ok, _entry} =
      Publishing.record_publication_event(
        "fixture:#{System.unique_integer([:positive])}",
        content_sha,
        :accepted,
        generation_id: generation_id,
        reason: "Fixture content"
      )

    :ok
  end

  defp maybe_accept_fixture_generation(
         _content,
         _generation_id,
         _content_sha,
         true
       ) do
    :ok
  end
end
