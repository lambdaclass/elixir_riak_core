defmodule MyRiax.Service do

  def ping(v\\1) do
    idx = :riak_core_util.chash_key({"civile", "ping#{v}"})
    pref_list = :riak_core_apl.get_primary_apl(idx, 1, MyRiax.Service)

    [{index_node, _type}] = pref_list

    :riak_core_vnode_master.sync_spawn_command(index_node, {:ping, v}, MyRiax.VNode_master)
  end
end
