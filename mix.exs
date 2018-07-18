defmodule Adjust.MixProject do
  use Mix.Project

  def project do
    [
      app: :adjust,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Adjust.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:postgrex, "~> 0.13"},
      {:cowboy, "~> 2.0"},
      {:plug, "~> 1.0"}
    ]
  end
end
