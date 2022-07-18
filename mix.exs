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
      # {exometer_core, {git, "https://github.com/Feuerlabs/exometer_core.git", {tag, "1.6.1"}}},
      # I had to fork both riak core an its dependency
      # clique to make it work with Elixir.
      {:hut, "~> 1.3", manager: :rebar3, override: true},
      {:riak_core,
       manager: :rebar3, git: "https://github.com/fkrause98/riak_core", ref: "develop"},
      {:local_cluster, "~> 1.2", only: [:test]},
      # {:parse_trans, "~> 3.4.1", manager: :rebar3, override: true},
      {:exometer_core,
       git: "https://github.com/Feuerlabs/exometer_core", tag: "1.6.1", override: true}
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
