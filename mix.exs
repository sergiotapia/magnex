defmodule Magnex.MixProject do
  use Mix.Project

  def project do
    [
      app: :magnex,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Magnex",
      source_url: "https://github.com/sergiotapia/magnex",
      homepage_url: "https://github.com/sergiotapia/magnex",
      docs: [
        main: "Magnex",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1", only: [:dev, :test]},
      {:floki, "~> 0.20.4"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
