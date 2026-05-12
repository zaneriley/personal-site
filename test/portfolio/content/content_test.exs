defmodule Portfolio.Content.ContentTest do
  use Portfolio.DataCase
  alias Portfolio.Content
  alias Portfolio.Content.PublicRead.Scope
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.ContentFixtures
  alias Portfolio.Content.TranslationRepository
  require Logger

  describe "content retrieval" do
    test "get!/2 returns the content item with given id" do
      note = ContentFixtures.note_fixture()
      retrieved_note = Content.get!("note", note.id)
      assert retrieved_note.id == note.id
      assert retrieved_note.title == note.title
      assert retrieved_note.content == note.content
      assert is_list(retrieved_note.compiled_content)
    end

    test "get!/2 returns the content item with given url" do
      note = ContentFixtures.note_fixture()
      retrieved_note = Content.get!("note", note.url)
      assert retrieved_note.id == note.id
      assert retrieved_note.title == note.title
      assert retrieved_note.content == note.content
      assert is_list(retrieved_note.compiled_content)
    end

    test "get!/2 raises Ecto.NoResultsError for non-existent content" do
      assert_raise Ecto.NoResultsError, fn ->
        Content.get!("note", Ecto.UUID.generate())
      end
    end

    test "get!/2 hides draft rows in the live publication generation" do
      live_note =
        ContentFixtures.note_fixture(%{"url" => "live-row-before-draft"},
          skip_translations: true
        )

      note =
        ContentFixtures.note_fixture(
          %{
            "url" => "draft-row-in-live-generation",
            "is_draft" => true
          },
          skip_translations: true
        )

      assert note.publication_generation_id ==
               live_note.publication_generation_id

      assert_raise Ecto.NoResultsError, fn ->
        Content.get!("note", note.url)
      end
    end

    test "get!/2 hides unpublished rows in the live publication generation" do
      live_note =
        ContentFixtures.note_fixture(%{"url" => "live-row-before-unpublished"},
          skip_translations: true
        )

      note =
        ContentFixtures.note_fixture(
          %{
            "url" => "unpublished-row-in-live-generation",
            "published_at" => nil
          },
          skip_translations: true
        )

      assert note.publication_generation_id ==
               live_note.publication_generation_id

      assert_raise Ecto.NoResultsError, fn ->
        Content.get!("note", note.url)
      end
    end

    test "get!/2 raises ArgumentError for invalid id_or_url" do
      assert_raise ArgumentError, fn ->
        Content.get!("note", 123)
      end
    end
  end

  describe "content aliases" do
    test "get_alias_redirect/3 returns the live content item for a legacy URL" do
      note =
        ContentFixtures.note_fixture(
          %{
            "url" => "new-note-url",
            "aliases" => ["old-note-url"]
          },
          skip_translations: true
        )

      assert {:ok, redirected_note} =
               Content.get_alias_redirect(
                 Scope.current(),
                 "note",
                 "old-note-url"
               )

      assert redirected_note.id == note.id
      assert redirected_note.url == "new-note-url"
    end

    test "get_alias_redirect/3 does not treat canonical URLs as aliases" do
      ContentFixtures.note_fixture(
        %{
          "url" => "canonical-note-url",
          "aliases" => ["old-canonical-note-url"]
        },
        skip_translations: true
      )

      assert {:error, :not_found} =
               Content.get_alias_redirect(
                 Scope.current(),
                 "note",
                 "canonical-note-url"
               )
    end

    test "get_alias_redirect/3 hides draft aliases in the live generation" do
      live_note =
        ContentFixtures.note_fixture(%{"url" => "live-before-draft-alias"},
          skip_translations: true
        )

      ContentFixtures.note_fixture(
        %{
          "url" => "draft-note-url",
          "aliases" => ["old-draft-note-url"],
          "is_draft" => true
        },
        skip_translations: true
      )

      assert is_binary(live_note.publication_generation_id)

      assert {:error, :not_found} =
               Content.get_alias_redirect(
                 Scope.current(),
                 "note",
                 "old-draft-note-url"
               )
    end

    test "get_alias_redirect/3 hides unpublished aliases in the live generation" do
      live_note =
        ContentFixtures.note_fixture(
          %{"url" => "live-before-unpublished-alias"},
          skip_translations: true
        )

      ContentFixtures.note_fixture(
        %{
          "url" => "unpublished-note-url",
          "aliases" => ["old-unpublished-note-url"],
          "published_at" => nil
        },
        skip_translations: true
      )

      assert is_binary(live_note.publication_generation_id)

      assert {:error, :not_found} =
               Content.get_alias_redirect(
                 Scope.current(),
                 "note",
                 "old-unpublished-note-url"
               )
    end
  end

  describe "content creation" do
    test "create/2 with valid data creates a note" do
      valid_attrs = %{
        "title" => "New Note",
        "content" => "Some content",
        "url" => "new-note",
        "locale" => "en"
      }

      assert {:ok, %Note{} = note} = Content.create("note", valid_attrs)
      assert note.title == "New Note"
      assert note.content == "Some content"
      assert note.url == "new-note"
    end

    test "create/2 with invalid content_type returns error" do
      invalid_attrs = %{
        "content_type" => "invalid",
        "title" => "Test",
        "content" => "Content",
        "locale" => "en"
      }

      assert {:error, :invalid_content_type} =
               Content.create("invalid", invalid_attrs)
    end
  end

  describe "content update" do
    test "update/3 with valid data updates the note" do
      note = ContentFixtures.note_fixture()
      update_attrs = %{"title" => "Updated Title"}

      assert {:ok, %Note{} = updated_note} =
               Content.update("note", note, update_attrs)

      assert updated_note.title == "Updated Title"
    end

    test "update/3 with invalid data returns error changeset" do
      note = ContentFixtures.note_fixture()
      invalid_attrs = %{"title" => nil}

      assert {:error, %Ecto.Changeset{}} =
               Content.update("note", note, invalid_attrs)

      updated_note = Content.get!("note", note.id)
      assert note.id == updated_note.id
      assert note.title == updated_note.title
      assert note.content == updated_note.content
      assert is_list(updated_note.compiled_content)
    end
  end

  describe "content change" do
    test "change/3 returns error for invalid content type" do
      assert {:error, :invalid_content_type} =
               Content.change("invalid_type", %{}, %{})
    end

    test "change/3 returns changeset for valid content type" do
      note = ContentFixtures.note_fixture()

      assert %Ecto.Changeset{} =
               Content.change("note", note, %{title: "New Title"})
    end
  end

  describe "content deletion" do
    test "delete/2 deletes an unpublished note" do
      note = ContentFixtures.note_fixture(%{}, publication_generation_id: nil)
      assert {:ok, %Note{}} = Content.delete("note", note)
      refute Portfolio.Repo.get(Note, note.id)
    end

    test "delete/2 refuses to delete a published note" do
      note = ContentFixtures.note_fixture()

      assert {:error, changeset} = Content.delete("note", note)

      assert %{
               publication_generation_id: [
                 "cannot be deleted outside the publication workflow"
               ]
             } = errors_on(changeset)
    end
  end

  describe "content with translations" do
    setup do
      Portfolio.DataCase.clear_cache()
      :ok
    end

    test "get_with_translations/3 returns content with specified locale translations" do
      # Create a note in the default locale (English)
      note =
        ContentFixtures.note_fixture(
          %{
            "title" => "English Title",
            "content" => "English Content",
            "url" => "test-note-with-translations",
            "locale" => "en"
          },
          skip_translations: true
        )

      # Add a French translation
      {:ok, french_translation} =
        Content.upsert_from_file("note", %{
          "title" => "Titre Français",
          "url" => "test-note-with-translations",
          "locale" => "fr",
          trusted_publication_generation_id: note.publication_generation_id
        })

      Logger.debug("French translation created: #{inspect(french_translation)}")

      # Retrieve the note with French translations
      {:ok, retrieved_note, translations, compiled_content} =
        Content.get_with_translations("note", note.url, "fr")

      Logger.debug("Retrieved translations: #{inspect(translations)}")

      # Assertions
      assert retrieved_note.id == note.id
      assert retrieved_note.title == "English Title"
      assert translations["title"] == "Titre Français"
      assert translations["url"] == "test-note-with-translations"
      assert is_list(compiled_content)
    end

    test "get_with_translations handles partial translations" do
      # Create a note
      note =
        ContentFixtures.note_fixture(
          %{
            "title" => "English Title",
            "content" => "English Content",
            "url" => "partial-translation-note",
            "locale" => "en"
          },
          skip_translations: true
        )

      # Create partial translation
      {:ok, _} =
        Content.upsert_from_file("note", %{
          "title" => "部分的な日本語のタイトル",
          "url" => "partial-translation-note",
          "locale" => "ja",
          trusted_publication_generation_id: note.publication_generation_id
        })

      # Retrieve content with translations
      {:ok, _content, translations, _compiled_content} =
        Content.get_with_translations("note", note.url, "ja")

      # Assertions
      assert translations["title"] == "部分的な日本語のタイトル"
      assert Map.has_key?(translations, "content") == false
    end

    test "get_content_with_translations returns default content for unsupported locale" do
      note = ContentFixtures.note_fixture()
      # Assuming Spanish translations are not provided
      unsupported_locale = "es"

      {:ok, content, translations, _compiled_content} =
        Content.get_with_translations("note", note.url, unsupported_locale)

      # Assuming English is the default
      assert content.locale == "en"
      assert Map.keys(translations) == []
    end
  end

  describe "file-based operations" do
    test "upsert_from_file/2 creates new content from file data" do
      attrs = %{
        "url" => "new-file-note",
        "locale" => "en",
        "title" => "New File Note",
        "content" => "Content from file"
      }

      assert {:ok, %Note{} = note} = Content.upsert_from_file("note", attrs)
      assert note.url == "new-file-note"
      assert note.title == "New File Note"
    end

    test "upsert_from_file/2 updates existing content from file data" do
      existing_note =
        ContentFixtures.note_fixture(%{"url" => "existing-file-note"},
          publication_generation_id: nil
        )

      attrs = %{
        "url" => "existing-file-note",
        "locale" => "en",
        "title" => "Updated File Note",
        "content" => "Updated content from file"
      }

      assert {:ok, %Note{} = updated_note} =
               Content.upsert_from_file("note", attrs)

      assert updated_note.id == existing_note.id
      assert updated_note.title == "Updated File Note"
    end

    test "upsert_from_file/2 handles atom content type" do
      attrs = %{
        "url" => "atom-type-note",
        "locale" => "en",
        "title" => "Atom Type Note",
        "content" => "Atom type note content"
      }

      assert {:ok, %Note{}} = Content.upsert_from_file(:note, attrs)
    end
  end

  describe "publication verdicts" do
    test "record_publication_event/4 appends by delivery ID and allows repeated content SHAs" do
      content_sha = String.duplicate("a", 40)

      {:ok, generation} =
        Portfolio.Content.Publishing.prepare_generation(content_sha)

      ContentFixtures.note_fixture(%{"url" => "ledger-live"},
        publication_generation_id: generation.id
      )

      assert {:ok, accepted} =
               Content.record_publication_event(
                 "delivery-content-accepted",
                 content_sha,
                 :accepted,
                 generation_id: generation.id,
                 promoted_paths: ["/content/notes/live/en.md"]
               )

      assert accepted.content_sha == content_sha
      assert accepted.status == "accepted"
      assert accepted.promoted_paths == ["/content/notes/live/en.md"]

      assert {:ok, rejected} =
               Content.record_publication_event(
                 "delivery-content-rejected",
                 content_sha,
                 :rejected,
                 reason: "Content promotion failed",
                 structured_errors: %{
                   "errors" => [
                     %{"path" => "/content/notes/live/en.md", "reason" => "bad"}
                   ]
                 }
               )

      assert rejected.id != accepted.id
      assert rejected.status == "rejected"
      assert rejected.reason == "Content promotion failed"
      assert rejected.promoted_paths == []

      assert rejected.structured_errors == %{
               "errors" => [
                 %{"path" => "/content/notes/live/en.md", "reason" => "bad"}
               ]
             }

      assert rejected == Content.get_publication_verdict(content_sha)
    end

    test "record_publication_event/4 rejects invalid SHAs" do
      assert {:error, changeset} =
               Content.record_publication_event(
                 "delivery-invalid-sha",
                 "not-a-sha",
                 :accepted
               )

      assert %{content_sha: ["has invalid format"]} = errors_on(changeset)
    end
  end

  describe "error handling" do
    test "get!/2 raises InvalidContentTypeError for invalid content type" do
      assert_raise Content.InvalidContentTypeError, fn ->
        Content.get!("invalid_type", "some-id")
      end
    end

    test "create/2 returns error for invalid content type" do
      assert {:error, :invalid_content_type} =
               Content.create("invalid_type", %{title: "Test"})
    end
  end

  describe "locale handling" do
    test "extract_locale/1 extracts locale from valid file path" do
      file_path = "priv/content/note/en/example.md"
      assert {:ok, "en"} = Content.extract_locale(file_path)
    end

    test "extract_locale/1 returns error for invalid file path" do
      file_path = "invalid/path/example.md"
      assert {:error, :invalid_file_path} = Content.extract_locale(file_path)
    end

    test "get_with_translations/3 returns content with specified locale translations" do
      # Create a note manually
      note =
        ContentFixtures.note_fixture(
          %{
            "title" => "English Title",
            "content" => "English Content",
            "url" => "test-note",
            "locale" => "en"
          },
          skip_translations: true
        )

      # Create translations manually
      TranslationRepository.create_or_update_translations(note, "fr", %{
        "title" => "Titre Français",
        "content" => "Contenu Français"
      })

      # Call get_with_translations
      {:ok, retrieved_note, translations, compiled_content} =
        Content.get_with_translations("note", note.url, "fr")

      # Assertions
      assert retrieved_note.id == note.id
      assert translations["title"] == "Titre Français"

      # Extract text content from AST
      ast_content = translations["content"]
      text_content = extract_text_from_ast(ast_content)

      assert text_content == "Contenu Français"
      assert is_list(compiled_content)
    end
  end

  describe "translation management" do
    test "handle concurrent updates to translations" do
      note = ContentFixtures.note_fixture()
      attrs1 = %{"title" => "タイトル1"}
      attrs2 = %{"title" => "タイトル2"}

      task1 =
        Task.async(fn ->
          Content.TranslationRepository.create_or_update_translations(
            note,
            "ja",
            attrs1
          )
        end)

      task2 =
        Task.async(fn ->
          Content.TranslationRepository.create_or_update_translations(
            note,
            "ja",
            attrs2
          )
        end)

      Task.await(task1)
      Task.await(task2)

      translations =
        Content.TranslationRepository.get_translations(note.id, "note", "ja")

      assert translations["title"] in ["タイトル1", "タイトル2"]
    end
  end

  # Helper function to extract text from AST
  defp extract_text_from_ast(nil), do: ""

  defp extract_text_from_ast(ast) when is_list(ast) do
    Enum.map_join(ast, "", &extract_text_from_ast/1)
  end

  defp extract_text_from_ast({_tag, _attrs, children, _meta}) do
    extract_text_from_ast(children)
  end

  defp extract_text_from_ast({:typography, _tag, _attrs, children, _meta}) do
    extract_text_from_ast(children)
  end

  defp extract_text_from_ast({:component, _type, _attrs, children, _meta}) do
    extract_text_from_ast(children)
  end

  defp extract_text_from_ast(text) when is_binary(text), do: text
  defp extract_text_from_ast(_), do: ""
end
