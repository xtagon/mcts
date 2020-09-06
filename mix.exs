defmodule MCTS.MixProject do
  use Mix.Project

  def project do
    [
      app: :mcts,
      version: "0.1.0",
      description: "Monte Carlo tree search (MCTS) for Elixir.",
      package: package(),
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "MCTS",
      source_url: "https://github.com/xtagon/mcts",
      homepage_url: "https://github.com/xtagon/mcts",
      docs: [
        main: "readme",
        extras: [
          "README.md",
          "CHANGELOG.md",
          "LICENSE.txt"
        ]
      ],

      # Coverage
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  def package do
    [
      # These are the default files included in the package
      files: ~w(
        .credo.exs
        .formatter.exs
        CHANGELOG.md
        LICENSE.txt
        README.md
        lib
        mix.exs
      ),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/xtagon/mcts"
      }
    ]
  end
end
