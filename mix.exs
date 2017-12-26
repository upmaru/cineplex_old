defmodule Compressor.Mixfile do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :compressor,
      version: "0.2.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger,
        :ffmpex,
        :honeydew,
        :httpoison,
        :blazay
      ],
      mod: {Compressor.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ffmpex, "~> 0.4.1"},
      {:honeydew, "~> 1.0.4"},
      {:download, "~> 0.0.4"},
      {:blazay, "~> 1.2.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
