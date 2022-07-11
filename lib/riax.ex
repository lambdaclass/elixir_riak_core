defmodule Riax do
  @moduledoc """
  Module to superficially interact with the implemented VNodes, and
  converage commands.
  As the implemented VNode is mostly a Key-Value store (for now)
  this module reflects that.
  """

  @doc """
  Store a value tied to a key
  """
  def put(key, value) do
    sync_command(key, {:put, {key, value}})
  end

  @doc """
  Store a value tiead to a key, but do not
  log it.

  Ideal to store fast.
  """
  def put(key, value, :no_log) do
    sync_command(key, {:put, :no_log, {key, value}})
  end

  @doc """
  Retrieve a key's value
  """
  def get(key) do
    sync_command(key, {:get, key})
  end

  @doc """
  Retrieve keys
  """
  def keys() do
    coverage_command(:keys)
  end

  @doc """
  Set an empty data state for every available VNode
  """
  def clear() do
    coverage_command(:clear)
  end

  @doc """
  Return every value of every available VNode
  """
  def values() do
    coverage_command(:values)
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
  Execute a command across every available VNode.
  This will start the coverage FSM (implemented in Riax.Coverage.Fsm), via
  the coverage supervisor, and gather the results from every VNode.
  """
  defp coverage_command(command, timeout \\ 5000) do
    req_id = :erlang.phash2(:erlang.monotonic_time())

    {:ok, _} = Riax.Coverage.Sup.start_fsm([req_id, self(), command, timeout])

    receive do
      {^req_id, val} -> val
    end
  end

  @doc """
  Return the node's name which is most likely
  to receive the given key as a parameter
  """
  def preferred_node_name(key) do
    {:ok, {_, name}} = preferred_node(key)
    name
  end

  @doc """
  Return the node's {index, name} tuple which is most likely
  to receive the given key as a parameter
  """
  defp preferred_node(key) do
    # Get the key's hash
    doc_idx = hash_key(key)
    # Get the preferred node for the given key
    case :riak_core_apl.get_apl(doc_idx, 1, :riax_service) do
      [{index_node, node_name}] -> {:ok, {index_node, node_name}}
      [] -> {:error, "Missing node for this service"}
    end
  end

  @doc """
  Use the VNode master to send a command
  to the VNode that receives the key
  """
  defp sync_command(key, command) do
    {:ok, node} = preferred_node(key)

    :riak_core_vnode_master.sync_spawn_command(node, command, Riax.VNode_master)
  end

  @doc """
  Hash a key with the default bucket being "riak"
  """
  defp hash_key(key), do: hash_key(key, <<"riak">>)

  @doc """
  Hash a key inside the given bucket name
  """
  defp hash_key(key, bucket) when is_binary(bucket) do
    :riak_core_util.chash_key({bucket, :erlang.term_to_binary(key)})
  end
end
