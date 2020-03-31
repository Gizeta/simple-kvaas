defmodule SimpleKVaaS.MixProject do
  use Mix.Project

  def project do
    [
      app: :simple_kvaas,
      version: "0.2.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {SimpleKVaaS, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 2.7"},
      {:eleveldb, "~> 2.2"},
      {:plug, "~> 1.10"},
      {:plug_cowboy, "~> 2.1"}
    ]
  end
end
