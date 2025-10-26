defmodule Zodish.MixProject do
  use Mix.Project

  @version "0.2.0"
  @github "https://github.com/rwillians/zodish"

  @description """
  Zodish is a validation library heavily inspired by JavaScript's Zod and ArkType.
  """

  def project do
    [
      app: :zodish,
      version: @version,
      description: @description,
      source_url: @github,
      homepage_url: @github,
      elixir: ">= 1.16.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [debug_info: Mix.env() == :dev],
      build_embedded: Mix.env() not in [:dev, :test],
      aliases: aliases(),
      package: package(),
      docs: [
        main: "readme",
        source_ref: "v#{@version}",
        source_url: @github,
        canonical: "http://hexdocs.pm/zodish/",
        extras: ["README.md", "LICENSE"]
      ],
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix],
        plt_add_deps: :apps_direct,
        flags: [:unmatched_returns, :error_handling, :underspecs]
      ]
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md LICENSE),
      maintainers: ["Rafael Willians"],
      contributors: ["Rafael Willians"],
      licenses: ["MIT"],
      links: %{
        GitHub: @github,
        Changelog: "#{@github}/releases"
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def aliases do
    [
      #
    ]
  end

  def cli do
    [
      #
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.4.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38.2", only: [:dev, :docs], runtime: false},
      {:decimal, ">= 2.0.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
