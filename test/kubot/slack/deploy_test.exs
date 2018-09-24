defmodule Kubot.Slack.Deploy do
  use ExUnit.Case, async: true
  import Mox
  setup :verify_on_exit!

  test "deploys to AWS" do
    aws_config = TestHelper.json_from_file("test/fixtures/kubot/aws/service.json")

    Kubot.AWS.Configuration
    |> expect(:fetch, fn "kubot.test", "app", "staging" ->
      {:ok, aws_config}
    end)

    Kubot.AWS.TaskDefinition
    |> expect(:register, fn _, _ ->
      {:ok, "task_arn"}
    end)

    Kubot.AWS.Service
    |> expect(:update, fn _ ->
      {:ok, {1, "service_arn"}}
    end)

    Kubot.Supervisor.CheckSupervisor
    |> expect(:enqueue, fn {"test-staging", "staging", _, _, _, 1} ->
      {:ok, true}
    end)

    reply =
      Kubot.Slack.command(
        "deploy",
        ["slack", "deploy", "staging", "app", "tag"],
        "channel",
        "slack"
      )

    msg = "Deployed tag to app staging\n" <> "> task `task_arn` service `service_arn`"
    assert reply == {:reply, msg}
  end
end
