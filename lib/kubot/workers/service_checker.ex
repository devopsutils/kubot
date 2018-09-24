defmodule Kubot.ServiceChecker do
  use GenServer
  use Slack
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def send(pid, params), do: GenServer.cast(pid, {:send, params})

  def handle_cast({:send, params}, state) do
    # 15 seconds
    Process.send_after(self(), {:check, params}, 1000 * 15)
    {:noreply, state}
  end

  def handle_info({:check, {service, cluster, arn, channel, slack, attempt}}, state) do
    Logger.debug("Checking (attempt #{attempt}) on task #{service}, arn: #{arn}")

    case Kubot.AWS.Service.describe(service, cluster) do
      {:ok,
       %{
         "deployments" => deployments,
         "taskDefinition" => td
       }} ->
        deployment =
          Enum.find(deployments, fn d ->
            d["taskDefinition"] == td
          end)

        case deployment do
          nil ->
            retry({service, cluster, arn, channel, slack, attempt})

          _ ->
            Logger.debug("Found correct deployment in service. ")

            case deployment["runningCount"] == deployment["desiredCount"] do
              true ->
                Logger.debug("Service tasks running equals desired count")

                Slack.Sends.send_message(
                  ":heavy_check_mark: Service (#{service}) is running " <>
                    "`#{deployment["runningCount"]} / #{deployment["desiredCount"]}` tasks\n" <>
                    "> task `#{arn}`",
                  channel,
                  slack
                )

              false ->
                Logger.debug(
                  "Service tasks running #{deployment["runningCount"]} NOT" <>
                    "equal to desired count #{deployment["desiredCount"]}"
                )

                retry({service, cluster, arn, channel, slack, attempt})
            end
        end

      _ ->
        Logger.warn("Kubot.ServiceChecker error describing service #{service}")
    end

    {:noreply, state}
  end

  def retry({service, cluster, arn, channel, slack, attempt}) do
    if(attempt <= 5) do
      Logger.debug("Retrying..")

      attempt = attempt + 1

      {service, cluster, arn, channel, slack, attempt}
      |> Kubot.Supervisor.CheckSupervisor.enqueue()
    else
      Logger.warn("Maxed attempts")

      Slack.Sends.send_message(
        ":warning: Did not find all running tasks for `#{arn}`. Please check AWS.\n" <>
          "> AWS: https://console.aws.amazon.com/ecs/home?" <>
          "#/clusters/#{cluster}/services/#{service}/tasks",
        channel,
        slack
      )
    end
  end
end
