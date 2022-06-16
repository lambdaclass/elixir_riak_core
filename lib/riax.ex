defmodule Riax do
  def put(key, value) do
    :rpc.call(node(), :rc_example, :put, [key, value])
  end

  def get(key) do
    :rpc.call(node(), :rc_example, :get, [key])
  end

  def keys() do
    :rpc.call(node(), :rc_example, :keys, [])
  end

  def ping() do
    ping(:os.timestamp())
  end

  def ping(key) do
    sync_command(key, :ping)
  end

  # This should be moved to something like
  # Riax.Helpers or an specific
  # behaviour?
  defp sync_command(key, command) do
    doc_idx = hash_key(key) |> IO.inspect(label: :dox_idx)
    preflist = :riak_core_apl.get_apl(doc_idx, 1, :riax)
    [index_node] = preflist
    :riak_core_vnode_master.sync_spawn_command(index_node, command, Riax.VnodeMaster)
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
