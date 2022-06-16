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
  end

  defp hash_key(key), do: hash_key(key, <<"riak">>)

  defp hash_key(key, bucket) when is_binary(bucket) do
    :riak_core_util.chash_key({bucket, :erlang.term_to_binary(key)})
  end
end
