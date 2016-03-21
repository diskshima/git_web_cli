defmodule BbCli.Mixfile do
  use Mix.Project

  def project do
    [app: :gw,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: BbCli],
     deps: deps]
  end

  def application do
    [applications: [:logger, :httpoison, :ex_link_header]]
  end

  defp deps do
    [
      {:poison, "~> 1.5"},
      {:ini, "~> 0.0.1"},
      {:oauth2, "~> 0.5"},
      {:dogma, "~> 0.0", only: :dev},
      {:ex_link_header, "~> 0.0.3"},
    ]
  end
end
