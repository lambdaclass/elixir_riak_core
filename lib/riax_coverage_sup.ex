defmodule Riax.CoverageSup do
  @behaviour Supervisor
  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: :coverage_sup)
  end

  def init([]) do
    children = [
      %{
        id: :undefined,
        start: {Riax.CoverageSup, :start_link, [Riax.CoverageSup]},
        restart: :temporary,
        type: :worker
      }
    ]

    Supervisor.init(children, strategy: :simple_one_for_one, max_restarts: 10, max_seconds: 10)
  end

  def start_fsm(args) do
    Supervisor.start_child(__MODULE__, args)
  end
end
