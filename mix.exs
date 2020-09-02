defmodule Mobius.MixProject do
  use Mix.Project

  def project do
    [
      app: :mobius,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Mobius.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gun, "~> 1.3"},
      {:castore, "~> 0.1"},
      {:jason, ">= 1.0.0"},
      {:excoveralls, "~> 0.13", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
