# Riax
An Elixir wrapper for Riak Core. 
Riak Core is distributed systems framework, written in erlang.
You can think of it as a building block for distributed and scalable systems.
# Riak Core:

## What is it?
It is based on the [Dynamo architecture](https://www.allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf),
meaning it is easy to scale horizontally and distributes work in a decentralized
manner. The great thing about Riak it's that it provides this architecture as a
reusable erlang library, meaning it can be used in any context
that benefits from a decentralized distribution of work.

## What's so great about it?
The key here is that Riak Core provides Consistent Hashing and Virtual Nodes.
Virtual Nodes distribute work between them, and Consistent Hashing lets us
routes commands to these Virtual Nodes. Note that many Virtual Nodes can run in
a Physical Node (i.e. a physical server) and can be easily set up or taken down.
Plus, the only thing that you have to do using this library is giving them names
and implement a behaviour, Riak handles the rest for you.

For example, a game server which handles requests from players could partition
players through said hashing to handle load, and ensure that players requests
are always handled on the same Virtual Node to ensure data locality. 

A distributed batch job handling system could also use consistent hashing and
routing to ensure jobs from the same batch are always handled by the same node,
or distribute the jobs across several partitions and then use the distributed
map-reduce queries to gather results.


Another example: Think about serving a dataset which you want quick 
access to, but It's too big to fit in memory. We could distribute said
files (or file) between Virtual Nodes, use and identifier (say, like an index)
hash it and assign it to a Virtual Node. 
This last use case is actually explained below.

## More about Hashing and VNodes:
Before performing an operation, a hashing function is applied to some data, a
key. The key hash will be used to decide which node in the cluster should be
responsible for executing the operation. The range of possible values the key
hash can take (the keyspace, usually depicted as a ring), is partitioned in
equally sized buckets, which are assigned to Virtual Vodes.

![The Ring](ring.png)

Virtual Nodes share what is called a keyspace.
The number of VNodes is fixed at cluster creation and a given hash value will
always belong to the same partition (i.e. the same VNode). The VNodes in turn
are evenly distributed across all available physical nodes. Note this
distribution isn't fixed as the keyspace partitioning is: the VNode distribution
can change if a physical node is added to the cluster or goes down.
# Setup:
   We recommend to use Elixir 1.13 and OTP 25.


## Single node:
1. First, add riax as a dependency to your mix.exs
    ```elixir
    defp deps do
        [
        {:riax, ">= 0.1.0", github: "lambdaclass/elixir_riak_core", branch: "main"}
        ]
    end
    ```
2. Then, you'll need a VNode implementation, [you can grab mine](https://github.com/lambdaclass/elixir_riak_core/blob/main/test/key_value/riax_kv.ex)
    If you want to. This is an example of a Virtual Node being used as Key-Value
    store. You can add it under lib/ or any other folder under elixirc_paths.
3. After that, you'll need a configuration for each Node, here's an example one:
    ```elixir
    # config/config.exs
    import Config
    config :riax, vnode: Riax.VNode.Impl

    config :riak_core,
    node: 'dev1@127.0.0.1',
    web_port: 8198,
    # Handoff is something we discuss
    # furhter in the Riax.VNode doc.
    handoff_port: 8199,
    # Where to save this node's ring
    # state
    ring_state_dir: 'ring_data_dir_1',
    platform_data_dir: 'data_1',
    # This is a config file for riak core,
    # we provide this one for you.
    schema_dirs: ['/deps/riax/priv']
    ```
4. Remember that the iex node name needs to match the one from your config, so
   now you can start your mix project with:
   ```bash
   iex --name dev1@127.0.0.1 -S mix run
    ```
   And then, try running Riax.ring_status/0 in iex, you should see something
   like this:
   ```
    iex(dev1@127.0.0.1)1> Riax.ring_status                                      
    ==================================== Nodes ====================================
    Node a: 64 (100.0%) dev1@127.0.0.1
    ==================================== Ring =====================================
    aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|
    :ok
   ``` 
   That's it! Up and running.

   ## Multiple nodes:
   Having multiple Virtual Nodes is a must. We're going to need a config file for 
   each one, so move our original config.exs to a dev1.exs file and create 
   new file under config/ called dev2.exs with the following content:
    ```elixir
    # config/dev2.exs
    import Config
    config :riax, vnode: Riax.VNode.Impl

    config :riak_core,
    node: 'dev2@127.0.0.1',
    web_port: 8298,
    handoff_port: 8299,
    ring_state_dir: './rings_state/ring_data_dir_2',
    platform_data_dir: './platform_data/data_2',
    schema_dirs: ['/deps/riax/priv']
    ```
    Now, you can try them locally on 2 separate terminal sessions (tmux, multiple termilas, terminal tabs... whatever you like), first run: 
    ```
    MIX_ENV=dev1 iex --name dev1@127.0.0.1 -S mix run
    ```
    Then, on the other session, run:
    ```
    MIX_ENV=dev2 iex --name dev2@127.0.0.1 -S mix run
    ```
    Try to join them, and handoff will start (handoff is the way on which
    partitions of the key-space are distributed between VNodes.)
    
    You could also create a makefile for ease of use:
    ```makefile
    node1:
        MIX_ENV=dev1 iex --name dev1@127.0.0.1 -S mix run

    node2:
        MIX_ENV=dev2 iex --name dev2@127.0.0.1 -S mix run
    ```

## Quick start:
  * Install dependencies with `mix deps.get`
  * Start the Riak Nodes with `make node1`, `make node2`, `make node3`, this will
    have to be done on separate terminals, or using something like Tmux.
  * Now, in one of the terminals you've just opened with `make node{i}` try to
    join the nodes using `:riak_core.join(node@host)` and use the Riax
    module as an API connecting to each Node.
    For example, supposing you're in node1's terminal:
    ```elixir
    iex(dev1@127.0.0.1)> :riak_core.join('dev2@127.0.0.1')
    iex(dev1@127.0.0.1)> :riak_core.join('dev3@127.0.0.1')
    iex(dev1@127.0.0.1)> Riax.ring_status
    ``` 
## Riak Setup:
  *  PLACEHOLDER: This is where the setup of Riak using the Elixir library
     would be. This could be either a setup here, o a link to the library.
     Either way, the tutorial would start with a working Riak key-value.
     I'm thinking of providing it along with the VNode implementation, as
     to no repeat the Erlang tutorial.
## Tutorial:
### Use Case:
  * Let's consider this use case: 
    - We have several, or one relatively big file that we want
      to provide.
    - The file, or files, are not fit to be stored in memory due to its/their 
      size.
    - We want to avoid disk reading whenever we can, and achieve
      high availability.
### Solution:
  * That's what we're going to address in this tutorial, 
    with the help of Riak Core.
  * The key thing here is that we can use several Riak Nodes to offer an
    in memory key-value storage. If we need more memory to store what we need,
    we can add another node to our cluster and Riak will handle the 
    details for us, provided we have an implemented VNode.
### Limiting VM Memory.
  * To simulate a situation where our file is too big to be stored in RAM,
  we're going to use a tweet dataset of around 3-4 GiB, [a CSV taken from Kaggle](https://www.kaggle.com/datasets/gauravduttakiit/bitcoin-tweets-16m-tweets-with-sentiment-tagged?resource=download) (you might need an account to download it, don't worry - it's free) and limit the available memory for our nodes.
  It's a collection of tweets about Bitcoin, we're only interested in 
  its size not its content, so it's useful.
  * Limiting available memory for a given BEAM instance it's quite easy,
  actually, we just need to use these arguments: `+MMsco true +MMscs X +Musac
  false` where X is an integer - the max accessible memory four our BEAM instance.
  You can read more about this [here](https://www.erlang.org/doc/man/erts_alloc.html) 
  * Let's try starting iex normally and read the zip file I've linked above.
    ``` elixir
    iex(1)> {:ok, file} = File.read("mbsa.csv.zip")
        {:ok,
        <<80, 75, 3, 4, 45, 0, 0, 0, 8, 0, 174, 188, 29, 83, 199, 127, 10, 192, 255,
        255, 255, 255, 255, 255, 255, 255, 8, 0, 20, 0, 109, 98, 115, 97, 46, 99,
        115, 118, 1, 0, 16, 0, 172, 145, 99, 186, 0, 0, ...>>}
    ```
  * Now, let's start iex with a memory limit of 512 MB:
 `iex --erl "+MMsco true +MMscs 512 +Musac false"` 

    ``` elixir
    iex(1)> file = File.read!("mbsa.csv.zip") 
    ** (File.Error) could not read file "mbsa.csv.zip": not enough memory
        (elixir 1.13.0) lib/file.ex:355: File.read!/1
    ```
      Working as intended, we tried to load a 1GB+ file while only having 512MB available.

  - The unzipped CSV has a size of 4.5 GB, give or take, so we're going to use 3 nodes,
    with 1500 MB each, let's use this makefile:

``` makefile
node1_limited:
	MIX_ENV=dev1 iex --erl "+MMsco true +MMscs 1500" --name dev1@127.0.0.1 -S mix run
node2_limited:
	MIX_ENV=dev2 iex --erl "+MMsco true +MMscs 1500" --name dev2@127.0.0.1 -S mix run
node3_limited:
	MIX_ENV=dev3 iex --erl "+MMsco true +MMscs 1500" --name dev3@127.0.0.1 -S mix run
```

### Setting up csv.
#### Storing:
 - Let's use NimbleCsv (it's maintained by JosŽ Valim so it must be good) to read our file, add  this to your dependencies in mix.exs
```elixir
      {:nimble_csv, "~> 1.1"}
```
-  We're going to use this functions, personally I'll add them to the Riax API module:
```elixir
  def distribute_csv(path) do
    :rpc.multicall(Riax, :setup_local_csv, [path])
  end
```
 ```elixir
 def store_csv(csv) do
    curr_node = node()

    csv
    |> File.stream!(read_ahead: 100_000)
    |> CSV.parse_stream()
    |> Stream.with_index()
    |> Stream.each(fn {row, indx} ->
      case preferred_node_name(indx) do
        ^curr_node ->
          put(indx, row, :no_log)

        _ ->
          nil
      end
    end)
    |> Stream.run()
  end
```
- `distribute_csv/1` receives a path to a csv file,
  and tells each running Riak Node (the ones joined using  :riak_core.join/1) with the `:rpc` module (more about it [here](https://www.erlang.org/doc/man/rpc.html)) to execute the `store_csv/1` function.
- `store_csv/1` indexes every row of the CSV and uses
 them as keys for storing each row. So we end up with an index -> row mapping. We only store the index row pair if the index key belongs to the running node partition.
The reasoning behind this is to simulate a 'real' situation where you have nodes running on different machines. We use `put/3` without logging because we know what we're storing.
#### VNode addition:
- To make this work, you're going to need to add
  this to your VNode implementation:
```elixir
      def handle_command({:put, :no_log, {k, v}}, _sender, state = %{data: data}) do
        new_data = Map.put(data, k, v)
        {:reply, :ok, %{state | data: new_data}}
      end
```
