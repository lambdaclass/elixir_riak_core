defmodule Riax.MixProject do
  use Mix.Project
  def project do
    [
      app: :riax,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:cuttlefish, "~> 3.0", git: "https://github.com/fkrause98/cuttlefish", override: true},
      {:riak_core,
       git: "https://github.com/basho/riak_core", ref: "f15acd3a87150431277eb754792ec24a0dc81d75", manager: :rebar3},
      {:hut, "~> 1.3", manager: :rebar3, override: true}
    ]
  end
end
