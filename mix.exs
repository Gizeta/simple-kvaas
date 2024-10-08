defmodule SimpleKVaaS.MixProject do
  use Mix.Project

  def project do
    [
      app: :simple_kvaas,
      version: "0.3.0",
      elixir: "~> 1.17",
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
      {:cowboy, "~> 2.12"},
      {:eleveldb, "~> 2.2"},
      {:plug, "~> 1.16"},
      {:plug_cowboy, "~> 2.7"}
    ]
  end
end
