defmodule Mobius.MixProject do
  use Mix.Project

  def project do
    [
      app: :mobius,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.html": :test, "test.ci": :test],
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
      {:hackney, "~> 1.17"},
      {:tesla, "~> 1.4.0"},
      {:excoveralls, "~> 0.13", only: :test},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      lint: "credo --strict",
      test: "test --no-start",
      "test.ci": ["test --color"]
    ]
  end
end
