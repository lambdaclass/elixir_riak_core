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

  def get_key_node(key) do
    case find_key(key) |> IO.inspect(label: :keys) do
      {_hash, node, _} -> node
      _ -> :no_key
    end
  end

  defp find_key(key) do
    {:ok, keys} = keys()

    keys
    |> Enum.find(fn tuple ->
      case tuple do
        {_hash, node, ^key} -> true
        _ -> false
      end
    end)
  end
end

defmodule Riax.VNode do
  require Logger
  @behaviour :riak_core_vnode

  require Record

  Record.defrecord(
    :fold_req_v2,
    :riak_core_fold_req_v2,
    Record.extract(:riak_core_fold_req_v2, from_lib: "riak_core/include/riak_core_vnode.hrl")
  )

  def start_vnode(partition) do
    :riak_core_vnode_master.get_vnode_pid(partition, __MODULE__)
  end

  def init([partition]) do
    {:ok, %{partition: partition, data: %{}}}
  end

  def handle_command({:ping, v}, _sender, state = %{partition: partition}) do
    Logger.info("Received ping command!", state)
    {:reply, {:pong, v + 1, node(), partition}, state}
  end

  def handle_command({:put, {k, v}}, _sender, state = %{data: data}) do
    Logger.info("PUT Key: #{k}, Value: #{v}", state)
    new_data = %{data | k => v}
    {:reply, :ok, %{state | data: new_data}}
  end

  def handle_command({:get, k}, _sender, state = %{data: data}) do
    Logger.info("GET #{k}", state)
    {:reply, Map.get(key, data), state}
  end

  def handle_command({:delete, k}, _sender, state = %{data: data}) do
    Logger.debug("DELETE #{k}", state)
    new_data = Map.delete(data, key)
    {:reply, Map.get(data, k, :not_found), %{state | data: new_data}}
  end

  def handle_command(message, _sender, state) do
    Logger.debug("unhandle command #{message}")
    {:noreply, state}
  end

  def handoff_finished(_dest, state = %{partition: partition}) do
    Logger.debug("handoff_finished #{partition}")
    {:ok, state}
  end

  @TODO
  def handle_handoff_command(
        fold_req_v2() = fold_req,
        _sender,
        state = %{data: data}
      ) do
    Logger.debug("handoff #{partition}")
    foldfun = fold_req_v2(fold_req, :foldfun)
    acc0 = fold_req_v2(fold_req, :acc0)

    acc_final = []
    {:reply, acc_final, state}
  end

  def handoff_starting(target_node, state = %{partition: partition}) do
    Logger.debug("Handoff starting with target: #{target_node}", state)
    {true, state}
  end

  def is_empty(state = %{data: data}) do
    is_empty = Map.size(data) == 1
    Logger.debug("is_empty #{partition}: #{is_empty}")
    {is_empty, state}
  end

  def terminate(reason, %{partition: partition}) do
    Logger.debug("terminate #{partition}: #{reason}")
    :ok
  end

  def delete(state) do
    Logger.debug("deleting the vnode data")
    {:ok, %{state | data: %{}}}
  end

  def handle_handoff_data(bin_data, state = %{data: data}) do
    {k, v} = :erlang.binary_to_term(bin_data)
    Logger.debug("receieved handoff data with key-value #{k} #{v}")
    new_data = %{data | key => val}
    {:reply, :ok, %{state | data => new_data}}
  end

  def encode_handoff_item(k, v) do
    Logger.debug("encode_handoff_item #{k} #{v}")
    :erlang.term_to_binary({k, v})
  end

  def handle_coverage(keys, _key_spaces, {_, req_id, _}, state = %{data: data}) do
    Logger.info("Received clear coverage: #{state}")
    new_state = %{state | data: %{}}
    {:reply, {req_id}, state}
  end

  def handle_exit(_pid, _reason, state) do
    {:noreply, state}
  end

  def handle_overload_command(_, _, _) do
    :ok
  end

  def handle_overload_info(_, _idx) do
    :ok
  end
end
