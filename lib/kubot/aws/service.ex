defmodule Kubot.AWS.Service do
  require Logger
  @callback update(map()) :: tuple()

  @keys [
    "cluster",
    "service",
    "desiredCount",
    "taskDefinition",
    "deploymentConfiguration",
    "networkConfiguration",
    "awsvpcConfiguration",
    "subnets",
    "securityGroups",
    "assignPublicIp",
    "platformVersion",
    "forceNewDeployment",
    "healthCheckGracePeriodSeconds"
  ]

  def create(
        %{
          "cluster" => _cluster,
          "service" => service,
          "desiredCount" => count,
          "taskDefinition" => task_definition
        } = opts
      ) do
    case ExAws.ECS.create_service(service, task_definition, count, Map.take(opts, @keys))
         |> ExAws.request() do
      {:ok, %{"service" => service}} ->
        %{"desiredCount" => desired_count, "serviceArn" => arn} = service
        {:ok, {desired_count, arn}}

      {:error, {:http_error, status, %{body: body}}} ->
        Logger.warn("AWS Service Create Error: #{body}")
        {:error, "AWS Service Create Error: #{status}"}
    end
  end

  @doc """
  Updates AWS ECS Service
  Returns {:ok, _}
  """
  def update(%{"cluster" => _cluster, "service" => service} = opts) do
    case ExAws.ECS.update_service(service, Map.take(opts, @keys))
         |> ExAws.request() do
      {:ok, %{"service" => service}} ->
        %{"desiredCount" => desired_count, "serviceArn" => arn} = service
        {:ok, {desired_count, arn}}

      {:error, {:http_error, status, %{body: body}}} ->
        Logger.warn("AWS Service Update Error: #{body}")
        {:error, "AWS Service Update Error: #{status}"}
    end
  end

  ## AWS ECS update_service syntax with placeholder values
  # {
  #  cluster: "String",
  #  service: "String", # required
  #  desired_count: 1,
  #  task_definition: "String",
  #  deployment_configuration: {
  #    maximum_percent: 1,
  #    minimum_healthy_percent: 1,
  #  },
  #  network_configuration: {
  #    awsvpc_configuration: {
  #      subnets: ["String"], # required
  #      security_groups: ["String"],
  #      assign_public_ip: "ENABLED", # accepts ENABLED, DISABLED
  #    },
  #  },
  #  platform_version: "String",
  #  force_new_deployment: false,
  #  health_check_grace_period_seconds: 1,
  # }

  @doc """
  Describes AWS ECS Service
  Returns {:ok, _}
  """
  def describe(service, cluster) do
    case ExAws.ECS.describe_services([service], %{"cluster" => cluster})
         |> ExAws.request() do
      {:ok, %{"services" => services}} ->
        service = services |> Enum.at(0)
        {:ok, service |> Map.drop(["events"])}

      {:error, {:http_error, status, %{body: body}}} ->
        Logger.warn("AWS Service Describe Error: #{body}")
        {:error, "AWS Service Describe Error: #{status}"}
    end
  end
end
