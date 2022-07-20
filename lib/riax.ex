defmodule Riax do
  @moduledoc """
  Module to interact with the VNode module
  given in the config.
  """

  @doc """
  Prints the [ring status](https://github.com/basho/riak_core/wiki#ring).
  The ring is, basically, a representation of the partitioned keys over nodes.
  Here's a [visual representation](https://github.com/lambdaclass/riak_core_tutorial/blob/master/ring.png)
  of said ring
  ## Example:
  Join 2 running nodes and print the ring, to see the key
  distribution (handoff) result:
  ```
  iex(dev2@127.0.0.1)3> Riax.ring_status
    ==================================== Nodes ====================================
    Node a: 64 (100.0%) dev2@127.0.0.1
    ==================================== Ring =====================================
    aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|
    :ok
  iex(dev2@127.0.0.1)13> Riax.join('dev1@127.0.0.1')
    13:51:21.258 [debug] Handoff starting with target: {:hinted, {913438523331814323877303020447676887284957839360, :"dev1@127.0.0.1"}}
    ...
  iex(dev2@127.0.0.1)6> Riax.ring_status
    ==================================== Nodes ====================================
    Node a: 64 (100.0%) dev1@127.0.0.1
    Node b: 0 (  0.0%) dev2@127.0.0.1
    ...
  # After a little while, run the command again
  # to check the ring status.
  iex(dev2@127.0.0.1)11> Riax.ring_status
    ==================================== Nodes ====================================
    Node a: 32 ( 50.0%) dev1@127.0.0.1
    Node b: 32 ( 50.0%) dev2@127.0.0.1
    ==================================== Ring =====================================
    abba|abba|abba|abba|abba|abba|abba|abba|abba|abba|abba|abba|abba|abba|abba|abba|
  ```
  """
  def ring_status() do
    {:ok, ring} = :riak_core_ring_manager.get_my_ring()
    :riak_core_ring.pretty_print(ring, [:legend])
  end

  @doc """
  Join the running node with the given argument node.
  This will automatically trigger the handoff - the nodes
  will start distributing partitions (and therefore, keys)
  between them. See the ring_status/0 example.
  """
  def join(node) do
    :riak_core.join(node)
  end

  @doc """
  This is actually the head of the Active Preference List:
  a list of the available VNodes to handle a given request.
  We always use the first available one.

  The VNode is represented and returned as: {index, node_name}.
  The first element denotes the first key in the partition the vnode is
  responsible for (as an integer), and the second element refers to
  the (physical) node the vnode is running on.


  ## Parameters:
    - key: can be any erlang term, but it is
      recommended to use numbers or strings.
    - bucket: is the name of the bucket for this key.
      A bucket is a "namespace" for a given Key.
      [Check this](https://github.com/basho/riak_core/wiki#buckets)
      for more.
  """
  def preferred_node(key, bucket \\ "riax") do
    doc_idx = hash_key(key, bucket)
    # Get the preferred node for the given key
    case :riak_core_apl.get_apl(doc_idx, 1, :riax_service) do
      [{index_node, node_name}] -> {:ok, {index_node, node_name}}
      [] -> {:error, "Missing node for this service"}
    end
  end

  @doc """
  Like `preferred_node/2`, but returns only
  the node's name.
  """
  def preferred_node_name(key, bucket \\ "riax") do
    {:ok, {_, name}} = preferred_node(key, bucket)
    name
  end

  @doc """
  Use the VNode master to send a *synchronous* command
  to the VNode that receives the key.
  Keep in mind this *blocks* the Master VNode's process,
  and will not be able multiple requests concurrently.
  ## Parameters:
    - key: Can be any erlang term, but it is
      recommended to use a number or a binary.
      This is used to determine on which
      partition will end up, and therefore which VNode
      handles the command.
    - bucket: Is the name of the bucket for this key.
    - command: The command to send to the VNode.
      This will try to match with the defined handle_command/3
      clause in the VNode module.
  ## Example:
  Let's say we have this function in our VNode module:
  ```
  def handle_command({:ping, v}, _sender, _state) do
    Logger.debug("Received ping command!", state)
    {:reply, {:pong, v + 1, node(), partition}, state}
  end
  ```
  We can interact with it like this:
  ```
  iex(dev1@127.0.0.1)> Riax.sync_command(1, "riax", {:ping, 1})
    13:13:08.004 [debug] Received ping command!
    {:pong, 2, :"dev1@127.0.0.1", 822094670998632891489572718402909198556462055424}
  ```
  """
  def sync_command(key, bucket \\ "riax", command) do
    {:ok, node} = preferred_node(key, bucket)

    :riak_core_vnode_master.sync_command(node, command, Riax.VNode_master)
  end

  @doc """
    Same as sync_command/3 but does not block the Master VNode's process.
    That is, it lets the Master VNode handle multiple requests concurrently.
  """
  def async_command(key, bucket \\ "riax", command) do
    {:ok, node} = preferred_node(key, bucket)

    :riak_core_vnode_master.sync_spawn_command(node, command, Riax.VNode_master)
  end

  @doc """
    Works like sync_command/3, but does not generate a response
    from the VNode that handles the request.
    In that way, it's similar to how GenServer.cast/2 works.
    Following sync_comand/3's example, its usage would be like this:
    ```
    iex(dev1@127.0.0.1)3> Riax.cast_command(1, "riax", {:ping, 1})
    :ok
    13:36:19.742 [debug] Received ping command!
    ```
    As you can see, the VNode does handle the request and logs it, but
    we only get an :ok as return value, like GenServer.cast/2.
  """
  def cast_command(key, bucket \\ "riax", command) do
    {:ok, node} = preferred_node(key, bucket)

    :riak_core_vnode_master.command(node, command, Riax.VNode_master)
  end

  @doc """
  Execute a command across every available VNode.
  This will start the coverage FSM (implemented in `Riax.Coverage.Fsm`), via
  the coverage supervisor, and gather the results from every VNode.
  Be careful, coverage commands can be quite expensive.
  The results are gathered as a list of 3 tuple elements: {partition, node, data}
  ## Parameters:
    - command: Command for the VNode, should match the first argument of a
               `handle_coverage/4` definition from your VNode.
    - timeout: timeout in microseconds, 5000 by default.

  ## Example:
  Let's say we want to call this function:
  ```
  def handle_coverage(:keys, _key_spaces, {_, req_id, _}, state = %{data: data}) do
    keys = Map.keys(data)
    {:reply, {req_id, keys}, state}
  end
  ```
  Then, we must do:
  ```
  iex(dev2@127.0.0.1)6> Riax.coverage_command(:keys)
    14:25:33.084 [info] Starting coverage request 74812649 keys
    {:ok,
    [
    {1027618338748291114361965898003636498195577569280, :"dev2@127.0.0.1", '\f'},
    {936274486415109681974235595958868809467081785344, :"dev2@127.0.0.1", [22]},
    {1415829711164312202009819681693899175291684651008, :"dev2@127.0.0.1", 'E'},
    {1392993748081016843912887106182707253109560705024, :"dev2@127.0.0.1", 'AV'},
    {959110449498405040071168171470060731649205731328, :"dev2@127.0.0.1", 'CZ'},
    ...
    ]
  ```
  """
  def coverage_command(command, timeout \\ 5000) do
    req_id = :erlang.phash2(:erlang.monotonic_time())

    {:ok, _} = Riax.Coverage.Sup.start_fsm([req_id, self(), command, timeout])

    receive do
      {^req_id, val} -> val
    end
  end

  @doc """
  Hash a key inside the given bucket name
  """
  defp hash_key(key, bucket) when is_binary(bucket) do
    :riak_core_util.chash_key({bucket, :erlang.term_to_binary(key)})
  end
end
