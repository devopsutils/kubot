defmodule Kubot.AWS.ContainerDefinition do
  def defaults(
        %{
          "cpu" => cpu,
          "environmentVariables" => environment_variables,
          "family" => family,
          "image" => image,
          "memory" => memory,
          "name" => name,
          "tag" => tag
        } = opts
      ) do
    command = string_or_empty_array(opts["command"])
    entry_point = string_or_empty_array(opts["entryPscroint"])
    port_mappings = opts["portMappings"] || []

    {[
       %{
         command: command,
         cpu: cpu,
         disableNetworking: nil,
         dnsSearchDomains: nil,
         dnsServers: nil,
         dockerLabels: nil,
         dockerSecurityOptions: nil,
         entryPoint: entry_point,
         environment: environment_variables,
         essential: true,
         extraHosts: nil,
         hostname: nil,
         image: "#{image}:#{tag}",
         links: [],
         logConfiguration: nil,
         memory: memory,
         mountPoints: [],
         name: name,
         portMappings: port_mappings,
         privileged: nil,
         readonlyRootFilesystem: nil,
         ulimits: nil,
         user: nil,
         volumesFrom: [],
         workingDirectory: nil
       }
     ], family}
  end

  defp string_or_empty_array(nil), do: []
  defp string_or_empty_array(list) when is_list(list), do: list
  defp string_or_empty_array(string), do: String.split(string, " ")
end
