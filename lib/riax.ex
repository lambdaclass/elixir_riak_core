defmodule Riax do
  @doc """
  Store a value tied to a key
  """
  def put(key, value) do
    sync_command(key, {:put, {key, value}})
  end

  @doc """
  Retrive a key's value
  """
  def get(key) do
    sync_command(key, {:get, key})
  end

  @doc """
  Retrieve keys
  """
  def keys() do
    sync_command(:key, :keys)
  end

  @doc """
  Print the ring status
  """
  def ring_status() do
    {:ok, ring} = :riak_core_ring_manager.get_my_ring()
    :riak_core_ring.pretty_print(ring, [:legend])
  end

  @doc """
  :pong!
  """
  def ping() do
    ping(:os.timestamp())
  end

  def ping(key) do
    sync_command(key, {:ping, key})
  end

  @doc """
  Return the node's name which is most likely
  to receive the given key as a parameter
  """
  def prefered_node_name(key) do
    {:ok, {_, name}} = prefered_node(key)
    name
  end

  @doc """
  Return the node's {index, name} tuple which is most likely
  to receive the given key as a parameter
  """
  defp prefered_node(key) do
    # Get the key's hash
    doc_idx = hash_key(key)
    # Get the prefered node for the given key
    case :riak_core_apl.get_apl(doc_idx, 1, :riax_service) do
      [{index_node, node_name}] -> {:ok, {index_node, node_name}}
      [] -> {:error, "Missing node for this service"}
    end
  end

  defp sync_command(key, command) do
    {:ok, node} = prefered_node(key)
    :riak_core_vnode_master.sync_spawn_command(node, command, Riax.VNode_master)
  end

  defp hash_key(key), do: hash_key(key, <<"riak">>)

  defp hash_key(key, bucket) when is_binary(bucket) do
    :riak_core_util.chash_key({bucket, :erlang.term_to_binary(key)})
  end
end
