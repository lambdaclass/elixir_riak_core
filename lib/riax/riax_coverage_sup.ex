defmodule Riax.Coverage.Sup do
  use Supervisor

  def start_link(_), do: start_link()
  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      %{
        id: :undefined,
        start: {Riax.Coverage.Fsm, :start_link, []},
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
