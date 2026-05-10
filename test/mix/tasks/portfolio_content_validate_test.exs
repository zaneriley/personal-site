defmodule Mix.Tasks.Portfolio.Content.ValidateTest do
  use Portfolio.DataCase, async: false

  alias Mix.Tasks.Portfolio.Content.Validate

  import Portfolio.ContentRepoHelpers

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    Mix.Task.reenable("app.start")
    Mix.Task.reenable("portfolio.content.validate")

    on_exit(fn ->
      Mix.shell(previous_shell)
      Mix.Task.reenable("app.start")
      Mix.Task.reenable("portfolio.content.validate")
    end)

    :ok
  end

  describe "run/1" do
    test "prints path and field-specific reasons without raw Elixir failure output" do
      content_path = tmp_dir!("validate-mix-task-field-error")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_file!(
        content_path,
        "notes/missing-title/en.md",
        """
        ---
        url: "missing-title"
        is_draft: false
        ---

        # Missing Title
        """
      )

      assert catch_exit(Validate.run([content_path])) == {:shutdown, 1}

      assert_received {:mix_shell, :error, [message]}

      assert message =~
               "Content validation failed for #{Path.expand(content_path)}"

      assert message =~ "notes/missing-title/en.md: title: can't be blank"
      refute message =~ "#Ecto.Changeset<"
      refute message =~ "** ("
      refute message =~ "stacktrace"
    end

    test "prints semantic alias collision reasons without raw tuples" do
      content_path = tmp_dir!("validate-mix-task-alias-error")
      on_exit(fn -> File.rm_rf!(content_path) end)

      write_note!(content_path, "notes/first-note/en.md",
        url: "first-note",
        aliases: ["shared-note"]
      )

      write_note!(content_path, "notes/second-note/en.md",
        url: "second-note",
        aliases: ["shared-note"]
      )

      assert catch_exit(Validate.run([content_path])) == {:shutdown, 1}

      assert_received {:mix_shell, :error, [message]}

      assert message =~ "notes/first-note/en.md"
      assert message =~ "notes/second-note/en.md"

      assert message =~
               "aliases: shared-note is used by more than one content file"

      refute message =~ "{:duplicate_alias"
    end
  end
end
