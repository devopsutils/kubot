defmodule Kubot.AWS.ConfigurationTest do
  use ExUnit.Case, async: true
  import Mox

  test "calls AWS S3" do
    Kubot.ExAwsMock
    |> expect(:request, fn -> {:ok, %{body: "{\"test\": 123}"}} end)

    Kubot.AWS.Configuration.fetch("bucket", "name", "env")
  end
end
