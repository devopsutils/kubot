defmodule Kubot.Slack do
  use Slack
  require Logger

  def handle_connect(slack, state) do
    Logger.debug("Connected as #{slack.me.name}")
    {:ok, state}
  end

  @doc """
  Handles slack events
  Returns {:ok, _}
  """
  def handle_event(slack_message = %{type: "message", text: text}, slack, state) do
    txt = String.split(text, " ")
    botname = Application.get_env(:kubot, :bot_name)

    user_verified =
      case Application.get_env(:kubot, :users) do
        nil ->
          true

        users ->
          String.split(users, ",") |> Enum.member?(slack_message.user)
      end

    cond do
      Enum.at(txt, 0) == botname && user_verified ->
        try do
          case command(Enum.at(txt, 1), txt, slack_message.channel, slack) do
            {:ok, _} ->
              {:ok, state}

            {:no_reploy, _} ->
              {:ok, state}

            {:error, msg} ->
              send_message(":warning: #{msg}", slack_message.channel, slack)
              {:ok, msg}

            {:reply, msg} ->
              send_message(msg, slack_message.channel, slack)
              {:ok, msg}
          end
        rescue
          RuntimeError -> Logger.error("Error!")
        end

      true ->
        {:ok, state}
    end
  end

  def handle_event(_, _, state), do: {:ok, state}

  @doc """
  Handles slack deploys
  botname deploy environment appname version
  Returns {:ok, _}
  """
  def command("deploy", txt, channel, slack) do
    environment = Enum.at(txt, 2)
    name = Enum.at(txt, 3)
    tag = Enum.at(txt, 4)

    case Kubot.AWS.Configuration.fetch(
           Application.get_env(:kubot, :aws_bucket),
           name,
           environment
         ) do
      {:ok, aws_config} ->
        {cds, family} =
          Kubot.AWS.ContainerDefinition.defaults(%{"tag" => tag} |> Map.merge(aws_config))

        case Kubot.AWS.TaskDefinition.register(cds, family) do
          {:ok, task} ->
            service_opts = aws_config |> Map.merge(%{"taskDefinition" => task})

            case Kubot.AWS.Service.update(service_opts) do
              {:ok, {_, arn}} ->
                msg =
                  "Deployed #{tag} to #{name} #{environment}\n" <>
                    "> task `#{task}` service `#{arn}`"

                # Enqueue Check working
                %{"cluster" => cluster, "service" => service} = service_opts

                Kubot.Supervisor.CheckSupervisor.enqueue({
                  service,
                  cluster,
                  task,
                  channel,
                  slack,
                  1
                })

                {:reply, msg}

              {:error, msg} ->
                {:error, msg}
            end

          {:error, msg} ->
            {:error, msg}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Handles slack scaling events
  botname scale environment appname desired_count
  Returns {:ok, _}
  """
  def command("scale", txt, _channel, _slack) do
    environment = Enum.at(txt, 2)
    name = Enum.at(txt, 3)

    case Kubot.AWS.Configuration.fetch(
           Application.get_env(:kubot, :aws_bucket),
           name,
           environment
         ) do
      {:ok, aws_config} ->
        %{"cluster" => cluster, "service" => service} = aws_config

        desired_count =
          case Enum.at(txt, 4) do
            "up" ->
              case Kubot.AWS.Service.describe(service, cluster) do
                {:ok, %{"desiredCount" => count}} -> {:ok, count + 1}
                {:error, msg} -> {:error, msg}
              end

            "down" ->
              case Kubot.AWS.Service.describe(service, cluster) do
                {:ok, %{"desiredCount" => count}} -> {:ok, count - 1}
                {:error, msg} -> {:error, msg}
              end

            count ->
              {:ok, String.to_integer(count)}
          end

        case desired_count do
          {:ok, desired_count} ->
            service_opts = aws_config |> Map.merge(%{"desiredCount" => desired_count})

            case Kubot.AWS.Service.update(service_opts) do
              {:ok, {desired_count, arn}} ->
                msg =
                  "Scaled #{name} `#{environment}` to #{desired_count}\n" <> "> service `#{arn}`"

                {:reply, msg}

              {:error, msg} ->
                {:error, msg}
            end

          {:error, msg} ->
            {:error, msg}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Handles slack scaling events
  botname describe environment appname
  Returns {:ok, _}
  """
  def command("describe", txt, _channel, _slack) do
    environment = Enum.at(txt, 2)
    name = Enum.at(txt, 3)

    case Kubot.AWS.Configuration.fetch(
           Application.get_env(:kubot, :aws_bucket),
           name,
           environment
         ) do
      {:ok, %{"cluster" => cluster, "service" => service}} ->
        case Kubot.AWS.Service.describe(service, cluster) do
          {:ok,
           %{
             "deployments" => deployments,
             "taskDefinition" => td,
             "serviceName" => service_name
           }} ->
            deployment =
              Enum.find(deployments, fn d ->
                d["taskDefinition"] == td
              end)

            case deployment do
              nil ->
                {:error, ":warning: No deployment found for #{td}"}

              _ ->
                msg =
                  ">#{name} (#{environment})\n" <>
                    "> Tasks running `#{deployment["runningCount"]} / #{
                      deployment["desiredCount"]
                    }`\n" <>
                    ">Task      `#{td}`\n>Service `#{service_name}`\n>Cluster `#{cluster}`\n" <>
                    "> AWS: https://console.aws.amazon.com/ecs/home?" <>
                    "#/clusters/#{cluster}/services/#{service}/tasks"

                {:reply, msg}
            end

          {:error, msg} ->
            {:error, msg}
        end

      {:error, msg} ->
        {:error, msg}
    end
  end

  @doc """
  Handles slack ECS service creation
  botname create-service environment appname version
  Returns {:ok, _}
  """
  def command("create-service", txt, channel, slack) do
    environment = Enum.at(txt, 2)
    name = Enum.at(txt, 3)
    tag = Enum.at(txt, 4)

    case Kubot.AWS.Configuration.fetch(
           Application.get_env(:kubot, :aws_bucket),
           name,
           environment
         ) do
      {:ok, aws_config} ->
        {cds, family} =
          Kubot.AWS.ContainerDefinition.defaults(%{"tag" => tag} |> Map.merge(aws_config))

        case Kubot.AWS.TaskDefinition.register(cds, family) do
          {:ok, task} ->
            service_opts = aws_config |> Map.merge(%{"taskDefinition" => task})

            case Kubot.AWS.Service.create(service_opts) do
              {:ok, {_, arn}} ->
                msg =
                  "Created service for to #{name} (#{environment})\n" <>
                    "Deployed #{tag} to #{name} #{environment}\n" <>
                    "> task `#{task}` service `#{arn}`"

                # Enqueue Check working
                %{"cluster" => cluster, "service" => service} = service_opts

                Kubot.Supervisor.CheckSupervisor.enqueue({
                  service,
                  cluster,
                  task,
                  channel,
                  slack,
                  1
                })

                {:reply, msg}

              {:error, msg} ->
                {:error, msg}
            end

          {:error, msg} ->
            {:error, msg}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def command(cmd, _, _, _) do
    {:error, "Unknown command `#{cmd}`"}
  end
end
