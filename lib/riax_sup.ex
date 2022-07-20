defmodule Riax.Supervisor do
  @moduledoc """
  Supervisor that spawns the Riak VNode Master and
  Coverage Supervisor.
  """
  use Supervisor

  def start_link([]) do
     # riak_core appends _sup to the application name.
    Supervisor.start_link(__MODULE__, [], name: :riax_sup)
  end

  def init([]) do
    :ok = :riak_core.register(vnode_module: Riax.VNode)
    # Give name to the service
    :ok = :riak_core_node_watcher.service_up(:riax_service, self())

    children = [
      %{
        id: Riax.VNode_master_worker,
        start: {:riak_core_vnode_master, :start_link, [Riax.VNode]},
        type: :worker
      },
      %{
        id: Riax.Coverage.Sup,
        start: {Riax.Coverage.Sup, :start_link, []},
        restart: :permanent,
        type: :supervisor,
        shutdown: :infinity
      }
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 10)
  end
end
