defmodule Riax.CoverageFsm do
  require Logger
  @behaviour :riak_core_coverage_fsm
  def start_link(req_id, client_pid, request, timeout) do
    :riak_core_coverage_fsm.start_link(__MODULE__, {:pid, req_id, client_pid}, [request, timeout])
  end

  def init({:pid, req_id, client_pid}, [request, timeout]) do
    Logger.info("Starting coverage request #{req_id} #{request}")
    state = %{req_id: req_id, from: client_pid, request: request, accum: []}
    {request, :allup, 1, 1, :riax_service, Riax.VNode_master, timeout, state}
  end

  def process_results({{_req_id, {_partition, _naode}}, []}, state), do: {:done, state}

  def process_results({{_req_id, {partition, node}}, data}, state = %{accum: accum}) do
    new_accum = [{partition, node, data} | accum]
    {:done, %{state | accum: new_accum}}
  end

  def finish(:clean, state = %{req_id: req_id, from: from, accum: accum}) do
    Logger.info("Finished coverage request #{req_id}")

    send(from, {req_id, {:ok, accum}})
    {:stop, :normal, state}
  end

  def finish({:error, reason}, state = %{req_id: req_id, from: from, accum: accum}) do
    Logger.info("Coverage query failed! Reason: #{reason}")

    send(from, {req_id, {:partial, reason, accum}})
    {:stop, :normal, state}
  end
end
