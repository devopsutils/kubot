defmodule Kubot.AWS.TaskDefinition do
  require Logger
  @callback register(list(), String.t()) :: tuple()

  def register(container_definitions, family) do
    case ExAws.ECS.register_task_definition(family, container_definitions) |> ExAws.request() do
      {:ok, %{"taskDefinition" => %{"taskDefinitionArn" => arn}}} ->
        Logger.debug("AWS Task Registration ARN: #{arn}")
        {:ok, arn}

      {:error, {:http_error, status, %{body: body}}} ->
        Logger.warn("AWS Task Registration Error: #{body}")
        {:error, "AWS Task Registration Error: #{status}"}
    end
  end
end
