defmodule Riax.VMaster do
  use Supervisor

  def start_link(_), do: start_link()
  def start_link() do
    # riak_core appends _sup to the application name.
    Supervisor.start_link(__MODULE__, [], name: :riax_sup)
  end

  def init(_args) do
    children = [
      %{
        id: Riax.VNode_master_worker,
        start: {:riak_core_vnode_master, :start_link, [Riax.VNode]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 10)
  end
end
