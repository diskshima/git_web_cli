defmodule BbCli.Mixfile do
  use Mix.Project

  def project do
    [app: :bb_cli,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: BbCli],
     deps: deps]
  end

  def application do
    [applications: [:logger, :httpoison]]
  end

  defp deps do
    [
      {:httpoison, "~> 0.8.0"},
      {:poison, "~> 1.5"},
      {:ini, "~> 0.0.1"},
    ]
  end
end
