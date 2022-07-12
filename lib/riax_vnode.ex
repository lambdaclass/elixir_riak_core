defmodule Riax.VNode do
  @moduledoc ~S"""
  A virtual node is an Elixir (or Erlang) process responsible for a partition of
  keys from [the ring](https://raw.githubusercontent.com/lambdaclass/riak_core_tutorial/master/ring.png).
  The key word here is virtual (as opposed to physical), because we can have
  many virtual nodes running on a physical node. In the picture, the colored
  squares are physical nodes. With consistent hashing, we can determine which
  node should handle a given key, depending on which partition (and therefore,
  VNode) the key ends up. The way that keys are distributed is the Handoff,
  which is explained on a section below. The virtual node is responsible for
  handling requests and can store data to be retrieved. It is important to bear
  in mind that VNodes are not bound to a particular to a particular physical
  node. They can be relocated to another physical nodes as new nodes are added
  (using Riax.join) or a certain physical node is not available. Adding new
  nodes easily is useful for horizontal scaling.

  To implement this Virtual Node, we provide an easy to use behaviour. Here's an
  example of using a Virtual Node as a Key-Value store.
  # Example
 ```
defmodule Riax.VNode.Impl do
    require Logger
    @behaviour Riax.VNode
    def init([partition]) do
        {:ok, %{partition: partition, data: %{}}}
    end

    def handle_command({:ping, v}, _sender, state = %{partition: partition}) do
        Logger.debug("Received ping command!", state)
        {:reply, {:pong, v + 1, node(), partition}, state}
    end

    def handle_command({:put, :no_log, {k, v}}, _sender, state = %{data: data}) do
        new_data = Map.put(data, k, v)
        {:reply, :ok, %{state | data: new_data}}
    end

    def handle_command({:put, {k, v}}, _sender, state = %{data: data}) do
        Logger.debug("PUT Key: #{inspect(k)}, Value: #{inspect(v)}", state)
        new_data = Map.put(data, k, v)
        {:reply, :ok, %{state | data: new_data}}
    end

    def handle_command({:get, key}, _sender, state = %{data: data}) do
        Logger.debug("GET #{key}", state)

        reply =
        case Map.get(data, key) do
            nil -> :not_found
            value -> value
        end

        {:reply, reply, state}
    end

    def handle_command({:delete, key}, _sender, state = %{data: data}) do
        Logger.debug("DELETE #{inspect(key)}", state)
        new_data = Map.delete(data, key)
        {:reply, Map.get(data, key, :not_found), %{state | data: new_data}}
    end

    def handle_command(message, _sender, state) do
        Logger.debug("unhandle command #{inspect(message)}")
        {:noreply, state}
    end

    def handoff_starting(target_node, state = %{partition: _partition}) do
        Logger.debug(
        "Handoff starting with target: #{inspect(target_node)} - State: #{inspect(state)}"
        )

        {true, state}
    end

    def handoff_finished(dest, state = %{partition: partition}) do
        Logger.debug(
        "Handoff finished with target: #{inspect(dest)}, partition: #{inspect(partition)}"
        )

        {:ok, state}
    end

    def handle_handoff_fold(fold_function, acc, _sender, state)
        when is_function(fold_function) do
        Logger.debug(">>>>> Handoff V2 <<<<<<")

        acc =
        state.data
        |> Enum.reduce(acc, fn {k, v}, acc ->
            fold_function.(k, v, acc)
        end)

        {:reply, acc, state}
    end

    def handle_handoff_command(request, sender, state) do
        handle_command(request, sender, state)
    end

    def is_empty(state) do
        is_empty = map_size(state) == 0
        {is_empty, state}
    end

    def delete(state) do
        Logger.debug("Deleting the vnode data")
        {:ok, %{state | data: %{}}}
    end

    def encode_handoff_item(k, v) do
        Logger.debug("Encode handoff item: #{k} #{v}")
        :erlang.term_to_binary({k, v})
    end

    def handle_handoff_data(bin_data, state) do
        Logger.debug("Handle handoff data - bin_data: #{inspect(bin_data)} - #{inspect(state)}")
        {k, v} = :erlang.binary_to_term(bin_data)
        new_state = Map.update(state, :data, %{}, fn data -> Map.put(data, k, v) end)
        {:reply, :ok, new_state}
    end

    def handle_coverage(:keys, _key_spaces, {_, req_id, _}, state = %{data: data}) do
        Logger.debug("Received keys coverage: #{inspect(state)}")
        keys = Map.keys(data)
        {:reply, {req_id, keys}, state}
    end

    def handle_coverage(:values, _key_spaces, {_, req_id, _}, state = %{data: data}) do
        Logger.debug("Received values coverage: #{inspect(state)}")
        values = Map.values(data)
        {:reply, {req_id, values}, state}
    end

    def handle_coverage(:clear, _key_spaces, {_, req_id, _}, state) do
        Logger.debug("Received clear coverage: #{inspect(state)} ")
        new_state = %{state | data: %{}}
        {:reply, {req_id, []}, new_state}
    end

    def handle_exit(pid, reason, state) do
        Logger.error(
        "Handling exit: self: #{inspect(self())} - pid: #{inspect(pid)} - reason: #{inspect(reason)} - state: #{inspect(state)}"
        )

        {:noreply, state}
    end

    def handoff_cancelled(state) do
        Logger.error("Handoff cancelled with state: #{state}")
        {:ok, state}
    end
  end
 ```

  If our setup is working, we can call it using the Riax module

  Example:
 ```
    iex(dev1@127.0.0.1)> Riax.sync_command 1, {:ping, 1}
        17:05:35.559 [debug] Received ping command!
        {:pong, 2, :"dev1@127.0.0.1", 822094670998632891489572718402909198556462055424}
    iex(dev1@127.0.0.1)2> Riax.sync_command(:some_identifier, {:put, {:my_key, :my_value}})
        17:09:57.727 [debug] PUT Key: :my_key, Value: :my_value
        :ok
    iex(dev1@127.0.0.1)3> Riax.sync_command(:some_identifier, {:get, :my_key})
        17:10:11.336 [debug] GET my_key
        :my_value
    iex(dev1@127.0.0.1)4> Riax.preferred_node(:some_identifier)
        {:ok, {639406966332270026714112114313373821099470487552, :"dev1@127.0.0.1"}}
  ```
   This tells us the key `:my_key` and value `:my_value` pair
   ended up in the Virtual Node `:"dev1@127.0.0.1"`

  # Handoff :

    Ownership of a partition (that is, key distribution between nodes) may be
    transferred from one virtual node to another in a different node when nodes
    join (via `Riax.join/1`) or are removed from the cluster, and under certain
    failure scenarios to guarantee high availability. If a node goes down
    unexpectedly, the partitions owned by the virtual nodes it contained will be
    temporarily handled by virtual nodes in other physical nodes. If the
    original node comes back up, ownership will eventually be transferred back
    to the original owners, also called primary virtual nodes. The virtual nodes
    that took over ownership in that scenario are called secondary virtual
    nodes. The process by which this ownership is negotiated and any relevant
    data is transferred to accomplish that is what we call a handoff. Transfer
    of ownership may also occur when adding or removing physical nodes to the
    cluster.

  # Handoff process:

    First of all, keep in mind that when the handoff is in progress,
    a VNode will handle its requests via `handle_handoff_command/3`,
    it can drop the request, forward it or handle it.
    When the handoff starts it works like this:

    1. The callback `handoff_starting/2` is called. If it returns a `{:false,
       state}` tuple, the handoff is cancelled. Else, it calls `is_empty/1` to
       check if the VNode has something to hand off.

    2. If `is_empty/1` it returns a `:false` tuple, the handoff continues

    3. `handle_handoff_fold/3` is called with a folding function and an
       accumulator as parameters. The provided accumulator works just fine with
       the Enum module. The given fold_function turns the VNode's state into
       key-value pairs (see the example) and, before sending them to its
       corresponding Virtual Node, calls encode_handoff_item/2 to encode them.

    4. Said encoding will be then decoded by `handle_handoff_data/2` in the receiving
       Virtual Node. When all the key-values are sent, `handoff_finished/2` is called.
  """
  require Logger
  @behaviour :riak_core_vnode
  @vnode_module Application.fetch_env!(:riax, :vnode)

  def start_vnode(partition) do
    :riak_core_vnode_master.get_vnode_pid(partition, __MODULE__)
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
  Responsible of answering commands
  sent with either `Riax.sync_command/3`, `Riax.async_command/3` or
  `Riax.cast_command/3`.
  # Parameters:
  - request: The command to be handled.
  - sender: The process sending the request.
  - state: The VNode's current state.
  Keep in mind that sender is :ignored when using `Riax.cast_command/3`.
  """
  @callback handle_command(request :: any(), sender :: sender(), state :: any()) ::
              :continue
              | {:reply, reply :: term(), new_mod_state :: term()}
              | {:noreply, new_mode_state :: term()}
              | {:async, work :: function(), from :: sender(), new_mod_state :: term()}
              | {:stop, reason :: term(), new_mod_state :: term()}

  @doc """
  Called when a handoff finishes.
  """
  @callback handoff_finished(handoff_dest(), state :: any()) ::
              {:ok, new_state :: term()}

  @doc """
  Callback that is called when a handoff starts.
  See the Handoff Process section.
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
  Called when the VNode data is to be deleted.
  Can be used for a preemptive cleanup of the VNode.
  """
  @callback delete(state :: any()) :: {:ok, new_state :: any()}

  @doc """
  When a handoff is in progress, data is received by the new vnode and must
  decode it and do something with it, this is done by this callback.
  """
  @callback handle_handoff_data(binary(), state :: any()) ::
              {:reply, :ok | {:error, reason :: term()}, state :: any()}

  @doc """
  Handles a command given by the `Riax.coverage_command/2` function.
  """
  @callback handle_coverage(request :: any(), keyspaces(), sender :: sender(), state :: any()) ::
              :continue
              | {:reply, reply :: any(), new_state :: any()}
              | {:noreply, new_state :: any()}
              | {:async, work :: function(), from :: sender(), new_state :: any()}
              | {:stop, reason :: any(), new_state :: any()}

  @doc """
  Callback called in the case that a process linked to the VNode process dies
  and allows the module using the behaviour to take appropiate action.
  """
  @callback handle_exit(pid(), reason :: any(), state :: any()) ::
              {:noreply, new_mod_state :: any()}
              | {:stop, reason :: any(), new_state :: any()}

  @doc """
  This function is called when a handoff process affecting this vnode process
  gets cancelled. It can be used to undo changes made in handoff_starting/2.
  """
  @callback handoff_cancelled(state :: any()) :: {:ok, new_state :: any()}

  @doc """
  This function is called before sending data to another running VNode during a
  handoff. The key-value pairs returned by the fold_function given to
  `handle_handoff_fold/4` will be encoded by this function.
  """
  @callback encode_handoff_item(key :: any(), value :: any()) :: {:ok, new_state :: any()}

  @doc """
  Set up VNode state and data structure. It recieves a list
  its assigned partition and should return the VNode's initial state.
  """
  @callback init([partition()]) :: {:ok, initial_state :: any()}

  @doc """
  Like `handle_handoff_command/3` but this function takes care of handling
  requests during a handoff.

  # Return
  This callback can also eturn a tuple that has as
  its first element :`reply,` `:noreply`, :`forward`, `:drop` or `:stop` tuple.
  If the function returns `:foward` it forwards the request to another VNode,
  `:drop` drops the request. Useful if, for example, you don't want to handle
  requests during a handoff.
  """
  @callback handle_handoff_command(
              request :: any(),
              acc :: any(),
              sender :: sender(),
              state :: any()
            ) ::
              {:reply, reply :: any(), new_state :: any()}
              | {:noreply, new_state :: any()}
              | {:forward, new_state :: any()}
              | {:drop, new_state :: any()}
              | {:stop, reason :: any(), new_state :: any()}

  @doc """
  This function has the job of converting the VNode state into a key-value pair.
  These key-value pairs will be then encoded by the `encode_handoff_item/2`
  callback.

  ## Parameters:

  - fold_function: Function that reduces/folds the VNode's actual state into key-value pairs.

  - acc: The initial accumulator for the fold_function.

  - sender: The process sending the handoff request.

  - state: VNode state.

  ## Return:
  The return values work just like in handle_handoff_command/3.
  """
  @callback handle_handoff_fold(
              fold_function :: fun(),
              acc :: any(),
              sender :: sender(),
              state :: any()
            ) ::
              {:reply, reply :: any(), new_state :: any()}
              | {:noreply, new_state :: any()}
              | {:forward, new_state :: any()}
              | {:drop, new_state :: any()}
              | {:stop, reason :: any(), new_state :: any()}

  # Delegate this functions to the library user,
  defdelegate init(partitions), to: @vnode_module

  defdelegate encode_handoff_item(k, v), to: @vnode_module

  defdelegate handle_command(request, sender, state), to: @vnode_module

  defdelegate handoff_finished(dest, state), to: @vnode_module

  defdelegate handoff_starting(target_node, state), to: @vnode_module

  defdelegate handoff_cancelled(state), to: @vnode_module

  defdelegate is_empty(state), to: @vnode_module

  defdelegate handle_handoff_data(bin_data, state), to: @vnode_module

  defdelegate handle_coverage(command, keyspaces, sender, state), to: @vnode_module

  defdelegate handle_exit(pid, reason, state), to: @vnode_module

  defdelegate delete(state), to: @vnode_module

  def terminate(reason, partition) do
    Logger.debug("terminate #{inspect(partition)}: #{inspect(reason)}")
    :ok
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

    @vnode_module.handle_handoff_fold(fold_function, accumulator, sender, state)
  end

  def handle_handoff_command(request, sender, state) do
    @vnode_module.handle_handoff_command(request, sender, state)
  end

end
