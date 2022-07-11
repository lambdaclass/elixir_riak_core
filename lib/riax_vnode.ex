defmodule Riax.VNode do
  @moduledoc """
  This module is an implementation of the VNode
  behaviour provided by Riak Core. It's meant to hide some
  ugly details of setting up a node using Riak Core directly
  as a dependency. The core logic, that is, init functions,
  handling of commands, etc. is delegated to a node given
  in the config. Said node must implement the `Riax.VNode` behaviour
  """
  require Logger
  @behaviour :riak_core_vnode
  @vnode_module Application.fetch_env!(:riax, :vnode)

  def start_vnode(partition) do
    :riak_core_vnode_master.get_vnode_pid(partition, __MODULE__)
  end

  def init([partition]) do
    {:ok, %{partition: partition, data: %{}}}
  end

  @type partition :: :chash.index_as_int()
  @type vnode_req() :: any()
  @type keyspaces() :: [{partition(), [partition()]}]
  @type sender_type() :: :fsm | :server | :raw
  @type sender() ::
          {sender_type(), reference() | tuple(), pid()}
          | {:server, :undefined, :undefined}
          | {:fsm, :undefined, pid()}
          | :ignore
  @type handoff_dest() ::
          {:riak_core_handoff_manager.ho_type(), {partition(), node()}}

  @doc """
  This callback is responsible of answering commands
  sent with either `Riax.sync_command/3`, `Riax.async_command/3` or
  `Riax.cast_command/3`.
  """
  @callback handle_command(request :: any(), sender :: sender(), mod_state :: any()) ::
              :continue
              | {:reply, reply :: term(), new_mod_state :: term()}
              | {:noreply, new_mode_state :: term()}
              | {:async, work :: function(), from :: sender(), new_mod_state :: term()}
              | {:stop, reason :: term(), new_mod_state :: term()}

  @doc """
  This callback is called when a handoff finishes.
  """
  @callback handoff_finished(handoff_dest(), state :: any()) ::
              {:ok, new_state :: term()}
  @doc """
  This callback is called when a handoff starts.
  """
  @callback handoff_starting(handoff_dest(), state :: any()) ::
              {boolean(), new_state :: any()}
  @doc """
  This callback is used to determine if the
  VNode's state data structure is empty.
  """
  @callback is_empty(state :: term()) ::
              {boolean(), new_state :: term()}
              | {false, size :: pos_integer(), new_state :: any()}
  @doc """
  Called when a
  """
  @callback delete(state :: any()) :: {:ok, new_state :: any()}

  @callback handle_handoff_data(binary(), state :: any()) ::
              {:reply, :ok | {:error, reason :: term()}, state :: any()}
  @callback handle_coverage(request :: any(), keyspaces(), sender :: sender(), state :: any()) ::
              :continue
              | {:reply, reply :: any(), new_state :: any()}
              | {:noreply, new_state :: any()}
              | {:async, work :: function(), from :: sender(), new_state :: any()}
              | {:stop, reason :: any(), new_state :: any()}
  @callback handle_exit(pid(), reason :: any(), state :: any()) ::
              {:noreply, new_mod_state :: any()}
              | {:stop, reason :: any(), new_state :: any()}
  @callback handoff_cancelled(state :: any()) :: {:ok, new_state :: any()}

  # Delegate this functions to the library user,
  defdelegate handle_command(request, sender, state), to: @vnode_module

  defdelegate handoff_finished(dest, state), to: @vnode_module

  defdelegate handoff_starting(target_node, state), to: @vnode_module

  defdelegate handoff_cancelled(state), to: @vnode_module

  defdelegate is_empty(state), to: @vnode_module

  defdelegate terminate(reason, partition), to: @vnode_module

  defdelegate handle_handoff_data(bin_data, state), to: @vnode_module

  defdelegate handle_coverage(command, keyspaces, sender, state), to: @vnode_module

  defdelegate handle_exit(pid, reason, state), to: @vnode_module

  defdelegate delete(state), to: @vnode_module

  def terminate(reason, %{partition: partition}) do
    Logger.debug("terminate #{inspect(partition)}: #{inspect(reason)}")
    :ok
  end
  def encode_handoff_item(k, v) do
    Logger.debug("Encode handoff item: #{k} #{v}")
    :erlang.term_to_binary({k, v})
  end

  def handle_overload_command(_, _, _), do: :ok
  def handle_overload_info(_, _idx), do: :ok

  require Record
  # Extract the fold function record definition from
  # the hrl file.
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

  @callback handle_handoff_command(
              fold_function :: fun(),
              acc :: any(),
              sender :: sender(),
              state :: any()
            ) ::
              {:reply, reply :: any(), new_state :: any()}
              | {:noreply, new_state :: any()}
              | {:async, work :: function(), from :: sender(), new_state :: any()}
              | {:forward, new_state :: any()}
              | {:drop, new_state :: any()}
              | {:stop, reason :: any(), new_state :: any()}
  def handle_handoff_command(fold_req_v1() = fold_req, sender, state) do
    Logger.debug(">>>>> Handoff V1 <<<<<<")
    fold_function = fold_req_v1(fold_req, :foldfun)
    accumulator = fold_req_v1(fold_req, :acc0)
    handle_handoff_command(fold_req_v2(foldfun: fold_function, acc0: accumulator), sender, state)
  end

  def handle_handoff_command(fold_req_v2() = fold_req, sender, state) do
    Logger.debug("Starting handoff v2")
    fold_function = fold_req_v2(fold_req, :foldfun)
    accumulator = fold_req_v2(fold_req, :acc0)

    @vnode_module.handle_handoff_command(fold_function, accumulator, sender, state)
  end
end
