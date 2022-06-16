# defmodule Civile.Service do
#   def ping(arg) do
#     idx = :riak_core_util.chash_key({"civile", "ping#{arg}"})
#     pref_list = :riak_core_apl.get_primary_apl(idx, 1, Riax.Vmaster)
#     [{index_node, _type}] = pref_list
#     :riak_core_vnode_master.sync_command(index_node, {:ping, arg}, Riax.Sup)
#   end
# end
