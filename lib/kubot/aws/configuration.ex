defmodule Kubot.AWS.Configuration do
  require Logger
  @callback fetch(String.t(), String.t(), String.t()) :: tuple()

  @doc """
  Fetches S3 configuration for AWS Credentials
  Returns {:ok, _}
  """
  def fetch(bucket, name, environment) do
    case ExAws.S3.get_object(bucket, "#{name}/#{environment}.json") |> ExAws.request() do
      {:ok, %{body: body}} ->
        case Poison.decode(body) do
          {:ok, json} ->
            {:ok, json}

          _ ->
            Logger.warn("AWS Configuration JSON parsing error: #{body}")
            {:error, "AWS Configuration JSON parsing error"}
        end

      {:error, {:http_error, status, %{body: body}}} ->
        Logger.warn("AWS Configuration Error: #{body}")
        {:error, "AWS Configuration Error: #{status}"}
    end
  end
end
