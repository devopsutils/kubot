defmodule Kubot do
  use Application
  import Supervisor.Spec

  def start(_, _) do
    case Mix.env() do
      :test ->
        Task.start(fn -> :timer.sleep(0) end)

      _ ->
        opts = [strategy: :one_for_one, name: Kubot.Supervisor]
        children = [supervisor(Kubot.Supervisor.CheckSupervisor, [])]
        Supervisor.start_link(children, opts)
        Slack.Bot.start_link(Kubot.Slack, [], Application.get_env(:kubot, :slack_api_key))
    end
  end
end
