defmodule Riax.MixProject do
  use Mix.Project

  def project do
    [
      app: :riax,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Riax.Application, []},
      applications: [:riak_core],
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/key_value"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:cuttlefish,
       git: "https://github.com/fkrause98/cuttlefish", manager: :rebar3, override: true},
      {:hut, "~> 1.3", manager: :rebar3, override: true},
      {:riak_core, manager: :rebar3, git: "https://github.com/basho/riak_core", ref: "develop"},
      {:nimble_csv, "~> 1.1"},
      {:local_cluster, "~> 1.2", only: [:test]},
      {:hackney, "~> 1.9"},
      {:parse_trans, "~> 3.4.1", override: true},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"],
      test: ["test --no-start"]
    ]
  end
end
