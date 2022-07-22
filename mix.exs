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
      deps: deps(),
      docs: [
        filter_modules: fn module, _ -> module in [Riax, Riax.VNode] end,
      ]
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
      # I had to fork the following to make this work:
      # - riak_core and this deps:
      #     - cuttlefish: https://github.com/fkrause98/cuttlefish/commit/b28c716c39f7c16b9dd680d787b3c8d8c77fca2a
      #     - exometer: https://github.com/fkrause98/cuttlefish/commit/b28c716c39f7c16b9dd680d787b3c8d8c77fca2a
      #     - hut, to make it use rebar3
      #     - parse_trans , to make it use rebar3
      # - For Riak Core, I had to change its rebar.config to use
      #   some of my forks of cuttlefish and exometer_core.
      # - For cuttlefish I only commented a post hook.
      # - For exometer_core I forked hut 2 to force it to use rebar3, as of now,
      #   when downloaded from hex.pm, it choose to use rebar which breaks with
      #   new elixir + erlang versions.
      {:riak_core, git: "https://github.com/fkrause98/riak_core", ref: "develop"},
      {:local_cluster, "~> 1.2", only: [:test]},
      {:ex_doc, "~> 0.14", only: [:dev, :test], runtime: false}
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
      test: ["test --no-start"],
      docs: ["docs -o docs -f html"]
    ]
  end
end
