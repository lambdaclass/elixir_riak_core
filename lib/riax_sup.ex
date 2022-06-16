defmodule Riax.VNodeMaster do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: :riax_sup)
    |> IO.inspect(label: :start_link_sup_result)
  end

  def init(_args) do
    v_master = worker(:riak_core_vnode_master, [Riax.Vnode], id: Riax.VNodeMaster)
    # v_master =
    #   {:riax_vnode_master, {:riak_core_vnode_master, :start_link, [Riax.Vnode]}, :permanent, 5000,
    #    :worker, [:riak_core_vnode_master]}

    # coverage_fsm = {
    #   :
    # }

    {:ok, {{:one_for_one, 5, 10}, [v_master]}}
  end
end
