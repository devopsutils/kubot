defmodule Kubot.MixProject do
  use Mix.Project

  def project do
    [
      app: :kubot,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Kubot, []},
      extra_applications: [:mix, :logger, :slack, :timber]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:distillery, "~> 2.0"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_ecs, "~> 0.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:slack, "~> 0.15.0"},
      {:sweet_xml, "~> 0.6"},
      {:timber, "~> 2.5"},
      {:httpoison, "~> 1.3"},
      {:poison, "~> 3.0"},
      {:mox, "~> 0.4", only: :test}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
