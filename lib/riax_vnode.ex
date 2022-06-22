defmodule Riax.VNode do
  require Logger
  @behaviour :riak_core_vnode

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
    new_data = Map.put(data, k, v)
    {:reply, :ok, %{state | data: new_data}}
  end

  def handle_command({:get, key}, _sender, state = %{data: data}) do
    Logger.info("GET #{key}", state)

    reply =
      case Map.get(data, key) do
        nil -> :not_found
        value -> value
      end

    {:reply, reply, state}
  end

  def handle_command({:delete, key}, _sender, state = %{data: data}) do
    Logger.debug("DELETE #{key}", state)
    new_data = Map.delete(data, key)
    {:reply, Map.get(data, key, :not_found), %{state | data: new_data}}
  end

  def handle_command(message, _sender, state) do
    Logger.debug("unhandle command #{message}")
    {:noreply, state}
  end

  def handoff_finished(dest, state = %{partition: partition}) do
    Logger.debug(
      "[Handoff] Finished with target: #{inspect(dest)}, partition: #{inspect(partition)}"
    )

    {:ok, state}
  end

  def handoff_starting(target_node, state = %{partition: partition}) do
    Logger.debug("Handoff starting with target: #{inspect(target_node)}", state)
    {true, state}
  end

  require Record

  Record.defrecord(
    :fold_req_v1,
    :riak_core_fold_req_v1,
    Record.extract(:riak_core_fold_req_v1, from_lib: "riak_core/include/riak_core_vnode.hrl")
  )

  Record.defrecord(
    :fold_req_v2,
    :riak_core_fold_req_v2,
    Record.extract(:riak_core_fold_req_v2, from_lib: "riak_core/include/riak_core_vnode.hrl")
  )

  def handle_handoff_command(fold_req_v1() = fold_req, sender, state) do
    Logger.debug(">>>>> Handoff V1 <<<<<<")
    foldfun = fold_req_v1(fold_req, :foldfun)
    acc0 = fold_req_v1(fold_req, :acc0)
    handle_handoff_command(fold_req_v2(foldfun: foldfun, acc0: acc0), sender, state)
  end

  def handle_handoff_command(fold_req_v2() = fold_req, _sender, state) do
    Logger.debug(">>>>> Handoff V2 <<<<<<")
    foldfun = fold_req_v2(fold_req, :foldfun)
    acc0 = fold_req_v2(fold_req, :acc0)

    acc_final =
      state.data
      |> Enum.reduce(acc0, fn {k, v}, acc ->
        foldfun.(k, v, acc)
      end)

    {:reply, acc_final, state}
  end

  def handle_handoff_command(request, sender, state) do
    Logger.debug(">>> Handoff generic request <<<")
    Logger.debug("[Handoff] Generic request: #{inspect(request)}")
    handle_command(request, sender, state)
  end

  def is_empty(state = %{data: data}) do
    is_empty = map_size(data) == 0
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

  def handle_handoff_data(bin_data, state) do
    Logger.debug("[handle_handoff_data] bin_data: #{inspect(bin_data)} - #{inspect(state)}")
    {k, v} = :erlang.binary_to_term(bin_data)
    new_state = Map.update(state, :data, %{}, fn data -> Map.put(data, k, v) end)
    {:reply, :ok, new_state}
  end

  def encode_handoff_item(k, v) do
    Logger.debug("encode_handoff_item #{k} #{v}")
    :erlang.term_to_binary({k, v})
  end

  def handle_coverage(:keys, _key_spaces, {_, req_id, _}, state = %{data: data}) do
    Logger.info("Received keys coverage: #{state}")
    keys = Map.keys(data)
    {:reply, {req_id, keys}, state}
  end

  def handle_coverage(:values, _key_spaces, {_, req_id, _}, state = %{data: data}) do
    Logger.info("Received values coverage: #{state}")
    values = Map.values(data)
    {:reply, {req_id, values}, state}
  end

  def handle_coverage(:clear, _key_spaces, {_, req_id, _}, state) do
    Logger.info("Receieved clear coverage: #{state} ")
    new_state = %{state | data: %{}}
    {:reply, {req_id, []}, new_state}
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
