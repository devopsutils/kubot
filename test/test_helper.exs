Mox.defmock(Kubot.AWS.Configuration, for: Kubot.AWS.Configuration)
Mox.defmock(Kubot.AWS.Service, for: Kubot.AWS.Service)
Mox.defmock(Kubot.AWS.TaskDefinition, for: Kubot.AWS.TaskDefinition)
Mox.defmock(Kubot.Supervisor.CheckSupervisor, for: Kubot.Supervisor.CheckSupervisor)
ExUnit.start()

defmodule TestHelper do
  def json_from_file(file) do
    File.read!("#{File.cwd!()}/#{file}")
    |> Poison.decode!()
  end
end
