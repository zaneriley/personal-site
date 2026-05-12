defmodule Mix.Tasks.Portfolio.Content.StatusTest do
  use Portfolio.DataCase, async: false

  import Portfolio.ContentFixtures

  alias Mix.Tasks.Portfolio.Content.Status
  alias Portfolio.Content.Publishing

  setup do
    previous_shell = Mix.shell()

    Mix.shell(Mix.Shell.Process)
    Mix.Task.reenable("app.start")

    on_exit(fn ->
      Mix.shell(previous_shell)
      Mix.Task.reenable("app.start")
    end)

    :ok
  end

  describe "run/1" do
    test "prints current, last-good, and rejected verdict details" do
      live_sha = String.duplicate("a", 40)
      rejected_sha = String.duplicate("b", 40)
      reason = "Content promotion failed"
      {:ok, generation} = Publishing.prepare_generation(live_sha)

      note_fixture(%{}, publication_generation_id: generation.id)

      assert {:ok, _accepted} =
               Publishing.record_publication_event(
                 "status-task-accepted",
                 live_sha,
                 :accepted,
                 generation_id: generation.id
               )

      assert {:ok, _rejected} =
               Publishing.record_publication_event(
                 "status-task-rejected",
                 rejected_sha,
                 :rejected,
                 reason: reason
               )

      assert :ok = Status.run([])

      assert_receive {:mix_shell, :info, [text_output]}

      assert text_output =~ "Current/live content SHA: #{live_sha}"
      assert text_output =~ "Last-good content SHA: #{live_sha}"
      assert text_output =~ "Last rejected SHA: #{rejected_sha}"
      assert text_output =~ "Last rejected reason: #{reason}"

      assert :ok = Status.run(["--json"])

      assert_receive {:mix_shell, :info, [json_output]}

      assert %{
               "current" => ^live_sha,
               "live" => ^live_sha,
               "last_good" => ^live_sha,
               "last_rejected_sha" => ^rejected_sha,
               "last_rejected_reason" => ^reason
             } = Jason.decode!(json_output)
    end
  end
end
