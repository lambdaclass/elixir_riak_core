defmodule Riax do
  def put(key, value) do
    sync_command(key, {:put, {key, value}})
  end

  def get(key) do
    sync_command(key, {:get, key})
  end

  def keys() do
    sync_command(:key, :keys)
  end

  def ping() do
    ping(:os.timestamp())
  end

  def ping(key) do
    sync_command(key, {:ping, 1})
  end

  defp sync_command(key, command) do
    # Get the key's hash
    doc_idx = hash_key(key)
    # Get the prefered node for the given key
    preflist = :riak_core_apl.get_apl(doc_idx, 1, :riax_service)
    [index_node] = preflist
    :riak_core_vnode_master.sync_spawn_command(index_node, command, Riax.VNode_master)
    # :riak_core_vnode_master.sync_spawn_command(index_node, command, Riax.VnodeMaster)
  end

  defp hash_key(key) do
    :riak_core_util.chash_key({<<"riak">>, :erlang.term_to_binary(key)})
  end

  defp coverage_command(command) do
    timeout = 5000
    req_id = :erlang.phash2(:erlang.monotonic_time())
    # {:ok, _} =
    receive do
      {req_id, val} ->
        val
    end
  end
end
