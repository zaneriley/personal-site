defmodule Portfolio.Content.Schemas.BaseSchemaTest do
  use Portfolio.DataCase

  alias Portfolio.Content.Schemas.CaseStudy
  alias Portfolio.Content.Schemas.Note

  defmodule TestSchemaDefault do
    use Portfolio.Content.Schemas.BaseSchema,
      schema_name: "test_schema_default",
      translatable_type: "test_default"
  end

  defmodule TestSchemaCustom do
    use Portfolio.Content.Schemas.BaseSchema,
      schema_name: "test_schema_custom",
      translatable_type: "test_custom",
      max_title_length: 100
  end

  describe "base schema" do
    test "common fields are present in Note and CaseStudy" do
      common_fields = [
        {:id, :binary_id},
        {:title, :string},
        {:url, :string},
        {:content, :string},
        {:introduction, :string},
        {:share_title, :string},
        {:share_description, :string},
        {:share_image_direction, :string},
        {:share_image_alt, :string},
        {:read_time, :integer},
        {:file_path, :string},
        {:locale, :string},
        {:published_at, :utc_datetime},
        {:is_draft, :boolean}
      ]

      assert Enum.all?(common_fields, fn {field, type} ->
               Note.__schema__(:type, field) == type &&
                 CaseStudy.__schema__(:type, field) == type
             end)
    end

    test "main-feed membership is castable from frontmatter on both types" do
      note_cs = Note.changeset(%Note{}, valid_attrs(%{"main_feed" => true}))
      assert note_cs.valid?
      assert Ecto.Changeset.get_change(note_cs, :main_feed) == true

      cs_attrs =
        valid_attrs(%{
          "main_feed" => false,
          "company" => "Acme",
          "role" => "Designer",
          "timeline" => "2024",
          "platforms" => ["web"],
          "sort_order" => 1
        })

      cs_cs = CaseStudy.changeset(%CaseStudy{}, cs_attrs)
      assert cs_cs.valid?
      assert Ecto.Changeset.get_change(cs_cs, :main_feed) == false
    end

    test "an absent main_feed key stays nil — nil means use the type default, never false" do
      changeset = Note.changeset(%Note{}, valid_attrs(%{}))
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :main_feed) == nil
    end

    test "validations are applied correctly" do
      changeset = Note.changeset(%Note{}, %{})
      assert changeset.errors[:title]
      assert changeset.errors[:content]
      assert changeset.errors[:locale]
    end

    test "URL uniqueness is enforced" do
      attrs = %{
        "title" => "Test",
        "content" => "Content",
        "locale" => "en",
        "url" => "test-url"
      }

      {:ok, _note} = Portfolio.Content.create("note", attrs)
      {:error, changeset} = Portfolio.Content.create("note", attrs)
      assert {"has already been taken", _} = changeset.errors[:url]
    end

    test "aliases must be old lowercase URL slugs" do
      changeset =
        Note.changeset(%Note{}, %{
          "title" => "Test",
          "content" => "Content",
          "locale" => "en",
          "url" => "new-note",
          "aliases" => [
            "old-note",
            "Old-Note",
            "/notes/old-note",
            "https://example.com/notes/old-note"
          ]
        })

      assert %{aliases: messages} = errors_on(changeset)

      assert "must be old slugs using lowercase letters, numbers, and hyphens" in messages
    end

    test "title length is validated" do
      long_title = String.duplicate("a", 256)
      attrs = %{"title" => long_title, "content" => "Content", "locale" => "en"}
      {:error, changeset} = Portfolio.Content.create("note", attrs)

      assert errors = changeset.errors[:title]
      {error_message, error_details} = errors

      assert error_message =~ "should be at most"
      assert error_message =~ "character(s)"
      assert Keyword.get(error_details, :count) == 255
      assert Keyword.get(error_details, :validation) == :length
      assert Keyword.get(error_details, :kind) == :max
    end

    test "translatable_type returns correct string" do
      assert Note.translatable_type() == "note"
      assert CaseStudy.translatable_type() == "case_study"
    end

    test "schema_name is required" do
      assert_raise RuntimeError, ":schema_name option is required", fn ->
        defmodule InvalidSchema do
          use Portfolio.Content.Schemas.BaseSchema, translatable_type: "invalid"
        end
      end
    end

    test "default max_title_length is 255" do
      changeset =
        TestSchemaDefault.changeset(%TestSchemaDefault{}, %{
          title: String.duplicate("a", 256)
        })

      assert {"should be at most %{count} character(s)", metadata} =
               changeset.errors[:title]

      assert metadata[:count] == 255
      assert metadata[:validation] == :length
      assert metadata[:kind] == :max
      assert metadata[:type] == :string
    end

    test "custom max_title_length is respected" do
      changeset =
        TestSchemaCustom.changeset(%TestSchemaCustom{}, %{
          title: String.duplicate("a", 101)
        })

      assert {"should be at most %{count} character(s)", metadata} =
               changeset.errors[:title]

      assert metadata[:count] == 100
      assert metadata[:validation] == :length
      assert metadata[:kind] == :max
      assert metadata[:type] == :string
    end
  end

  defp valid_attrs(overrides) do
    Map.merge(
      %{
        "title" => "A title",
        "content" => "Some content",
        "locale" => "en",
        "url" => "a-title-#{System.unique_integer([:positive])}"
      },
      overrides
    )
  end
end
