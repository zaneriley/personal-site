defmodule Portfolio.Content.FileManagement.PromoterTest do
  use Portfolio.DataCase, async: true

  alias Portfolio.Content.FileManagement.Promoter
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Content.Schemas.Translation
  alias Portfolio.Repo

  import Portfolio.ContentRepoHelpers

  describe "promote_changes/2" do
    test "promotes changed markdown into the database" do
      content_path = tmp_dir!("promote-change")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_note!(content_path, "notes/published-note/en.md")

      assert {:ok, result} =
               Promoter.promote_changes(content_path, %{
                 upsert: ["notes/published-note/en.md"],
                 delete: []
               })

      assert [promoted_path] = result.promoted

      assert promoted_path ==
               Path.expand("notes/published-note/en.md", content_path)

      assert %Note{} = note = Repo.get_by(Note, url: "published-note")
      assert note.title == "Published Note"
      assert note.is_draft == false
    end

    test "promotes optional share preview frontmatter into the database" do
      content_path = tmp_dir!("promote-share-preview-frontmatter")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_note!(content_path, "notes/published-note/en.md",
        share_title: "Share Title",
        share_description: "Share description",
        share_image_direction: "Quiet editorial card with Tokyo context",
        share_image_alt: "A share card for the published note"
      )

      assert {:ok, _result} =
               Promoter.promote_changes(content_path, %{
                 upsert: ["notes/published-note/en.md"],
                 delete: []
               })

      assert %Note{} = note = Repo.get_by(Note, url: "published-note")
      assert note.share_title == "Share Title"
      assert note.share_description == "Share description"

      assert note.share_image_direction ==
               "Quiet editorial card with Tokyo context"

      assert note.share_image_alt == "A share card for the published note"
    end

    test "promotes aliases frontmatter into the database" do
      content_path = tmp_dir!("promote-aliases-frontmatter")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_note!(content_path, "notes/published-note/en.md",
        aliases: ["old-published-note", "older-published-note"]
      )

      assert {:ok, _result} =
               Promoter.promote_changes(content_path, %{
                 upsert: ["notes/published-note/en.md"],
                 delete: []
               })

      assert %Note{} = note = Repo.get_by(Note, url: "published-note")
      assert note.aliases == ["old-published-note", "older-published-note"]
    end

    test "rejects aliases that duplicate another content alias" do
      content_path = tmp_dir!("reject-duplicate-aliases")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_note!(content_path, "notes/first-note/en.md",
        url: "first-note",
        aliases: ["shared-note"]
      )

      write_note!(content_path, "notes/second-note/en.md",
        url: "second-note",
        aliases: ["shared-note"]
      )

      assert {:error, result} = Promoter.promote_all(content_path)

      assert Enum.any?(
               result.errors,
               &match?(%{reason: {:duplicate_alias, "shared-note"}}, &1)
             )

      refute Repo.get_by(Note, url: "first-note")
      refute Repo.get_by(Note, url: "second-note")
    end

    test "rejects aliases that conflict with a canonical URL" do
      content_path = tmp_dir!("reject-canonical-alias")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_note!(content_path, "notes/alpha-note/en.md", url: "alpha-note")

      write_note!(content_path, "notes/beta-note/en.md",
        url: "beta-note",
        aliases: ["alpha-note"]
      )

      assert {:error, result} = Promoter.promote_all(content_path)

      assert Enum.any?(
               result.errors,
               &match?(
                 %{reason: {:alias_conflicts_with_url, "alpha-note"}},
                 &1
               )
             )

      refute Repo.get_by(Note, url: "alpha-note")
      refute Repo.get_by(Note, url: "beta-note")
    end

    test "rejects aliases that are not old URL slugs" do
      content_path = tmp_dir!("reject-invalid-alias-slug")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_note!(content_path, "notes/published-note/en.md",
        aliases: ["https://example.com/old-note"]
      )

      assert {:error, result} = Promoter.promote_all(content_path)

      assert [%{path: path, reason: changeset}] = result.errors

      assert path == Path.expand("notes/published-note/en.md", content_path)

      assert %{
               aliases: [
                 "must be old slugs using lowercase letters, numbers, and hyphens"
               ]
             } = errors_on(changeset)

      refute Repo.get_by(Note, url: "published-note")
    end

    test "rejects plaintext drafts before they can be promoted" do
      content_path = tmp_dir!("reject-plaintext-draft")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_note!(content_path, "notes/plaintext-draft/en.md",
        is_draft: true,
        url: "plaintext-draft"
      )

      assert {:error, result} = Promoter.promote_all(content_path)

      assert [
               %{
                 path: path,
                 reason: :unencrypted_draft
               }
             ] = result.errors

      assert path == Path.expand("notes/plaintext-draft/en.md", content_path)
      refute Repo.get_by(Note, url: "plaintext-draft")
    end

    test "rejects invalid content and keeps the previous database state" do
      content_path = tmp_dir!("reject-invalid")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_note!(content_path, "notes/published-note/en.md",
        title: "Good Title"
      )

      assert {:ok, _result} =
               Promoter.promote_changes(content_path, %{
                 upsert: ["notes/published-note/en.md"],
                 delete: []
               })

      write_invalid_note!(content_path, "notes/published-note/en.md")

      assert {:error, result} =
               Promoter.promote_changes(content_path, %{
                 upsert: ["notes/published-note/en.md"],
                 delete: []
               })

      assert [%{path: _path, reason: _reason}] = result.errors

      assert %Note{title: "Good Title"} =
               Repo.get_by(Note, url: "published-note")
    end

    test "removes content and translations for deleted markdown" do
      content_path = tmp_dir!("delete-markdown")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_note!(content_path, "notes/published-note/en.md")

      assert {:ok, _result} =
               Promoter.promote_changes(content_path, %{
                 upsert: ["notes/published-note/en.md"],
                 delete: []
               })

      note = Repo.get_by!(Note, url: "published-note")

      %Translation{}
      |> Translation.changeset(%{
        locale: "ja",
        field_name: "title",
        field_value: "公開ノート",
        translatable_id: note.id,
        translatable_type: "note"
      })
      |> Repo.insert!()

      assert {:ok, result} =
               Promoter.promote_changes(content_path, %{
                 upsert: [],
                 delete: ["notes/published-note/en.md"]
               })

      assert result.removed == [
               Path.expand("notes/published-note/en.md", content_path)
             ]

      refute Repo.get_by(Note, url: "published-note")
      assert [] = Repo.all(Translation)
    end

    test "rejects webhook paths outside the content base" do
      content_path = tmp_dir!("reject-escape")
      on_exit(fn -> File.rm_rf!(content_path) end)

      assert {:error, result} =
               Promoter.promote_changes(content_path, %{
                 upsert: ["../notes/escaped/en.md"],
                 delete: []
               })

      assert [
               %{
                 path: escaped_path,
                 reason: :path_outside_content_base
               }
             ] = result.errors

      assert escaped_path == Path.expand("../notes/escaped/en.md", content_path)
      refute Repo.get_by(Note, url: "escaped")
    end
  end

  describe "promote_all/1" do
    test "ignores markdown outside publishable content paths" do
      content_path = tmp_dir!("promote-all-ignore-docs")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_file!(content_path, "README.md", "# Content repo")
      write_note!(content_path, "notes/published-note/en.md")

      assert {:ok, result} = Promoter.promote_all(content_path)

      assert result.promoted == [
               Path.expand("notes/published-note/en.md", content_path)
             ]

      assert result.errors == []
      assert %Note{} = Repo.get_by(Note, url: "published-note")
    end

    test "prunes database entries whose source markdown disappeared" do
      content_path = tmp_dir!("promote-all-prune")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_note!(content_path, "notes/published-note/en.md")

      assert {:ok, _result} = Promoter.promote_all(content_path)
      assert %Note{} = Repo.get_by(Note, url: "published-note")

      File.rm!(Path.join(content_path, "notes/published-note/en.md"))

      assert {:ok, result} = Promoter.promote_all(content_path)

      assert result.removed == [
               Path.expand("notes/published-note/en.md", content_path)
             ]

      refute Repo.get_by(Note, url: "published-note")
    end
  end
end
