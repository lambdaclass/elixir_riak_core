# Riax
Riax is an Elixir wrapper for Riak Core. 
Riak Core is a distributed systems framework, written in Erlang.
You can think of it as a building block for distributed and scalable systems.
If you want to set it up with Erlang, we also have an [up-to-date (OTP 25)
tutorial](https://github.com/lambdaclass/riak_core_tutorial)
# Riak Core:
## What is it?
It is based on the [Dynamo architecture](https://www.allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf),
meaning it is easy to scale horizontally and distributes work in a decentralized
manner. The great thing about Riak it's that it provides this architecture as a
reusable Erlang library, meaning it can be used in any context
that benefits from a decentralized distribution of work.

## Why Riax? 
You must be thinking "ok, fine, this is an Erlang lib, I'll use it directly".
The setup of Riak Core can be tricky, specially from Elixir, this library
takes care of all the gory details for you - we suffered so you don't have to.

## What's so great about it?
The key here is that Riak Core provides Consistent Hashing and Virtual Nodes.
Virtual Nodes distribute work between them, and Consistent Hashing lets us
route commands to these Virtual Nodes. Note that many Virtual Nodes can run in
a Physical Node (i.e. a physical server) and can be easily set up or taken down.
Plus, the only thing that you have to do using this library is giving them names
and implement a behaviour, Riak handles the rest for you.

## Use cases:
The most intuitive and straight-forward use case is a key-value store in memory,
we've actually [implemented one here](https://github.com/lambdaclass/elixir_riak_core/blob/main/test/key_value/riax_kv.ex) for our tests.

A game server which handles requests from players could partition
players through said hashing to handle load, and ensure that players requests
are always handled on the same Virtual Node to ensure data locality. 

A distributed batch job handling system could also use consistent hashing and
routing to ensure jobs from the same batch are always handled by the same node,
or distribute the jobs across several partitions and then use the distributed
map-reduce queries to gather results.

Another example: Think about serving a dataset which you want quick 
access to, but It's too big to fit in memory. We could distribute said
files (or file) between Virtual Nodes, use an identifier (say, like an index)
hash it and assign it to a Virtual Node. Riak fits really well here, as it is
scales easily horizontally.
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
if you want to. This is an example of a Virtual Node being used as Key-Value
store. You can add it under lib/ or any other folder under elixirc_paths.
3. After that, you'll need a configuration for each Node, here's an example one:
```elixir
    # config/config.exs
    import Config
    # This tells riax which of or modules 
    # implements a VNode.
    config :riax, vnode: Riax.VNode.Impl

    config :riak_core,
    # Must be an Erlang long name
    node: 'dev@127.0.0.1',
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
    iex --name dev@127.0.0.1 -S mix run
    ```
And then, try running Riax.ring_status/0 in iex, you should see something
like this:
```bash
    iex(dev@127.0.0.1)1> Riax.ring_status
    ==================================== Nodes ====================================
    Node a: 64 (100.0%) dev@127.0.0.1
    ==================================== Ring =====================================
    aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|
    :ok
``` 
That's it! Up and running.

## Multiple nodes:
Having multiple Virtual Nodes is a must. We're going to need a config file for 
each one, so let's change it, config.exs can be something like this:
```elixir
    import Config
    config :riax, vnode: Riax.VNode.Impl

    import_config("#{Mix.env()}.exs")
```
    
Now, let's create 2 files, dev.exs (or add to it, if already exists) and dev2.exs under /config:

```elixir
    # dev.exs
    import Config
    config :riax, vnode: Riax.VNode.Impl

    config :riak_core,
      node: 'dev@127.0.0.1',
      web_port: 8198,
      handoff_port: 8199,
      ring_state_dir: 'ring_data_dir_1',
      platform_data_dir: 'data_1',
      schema_dirs: ['deps/riax/priv/']
```
```elixir
   #dev2.exs
    import Config

    config :riak_core,
    node: 'dev2@127.0.0.1',
    web_port: 8398,
    handoff_port: 8399,
    ring_state_dir: 'ring_data_dir_2',
    platform_data_dir: 'data_2',
    schema_dirs: ['deps/riax/priv/' ]
```
Now, you can try them locally on 2 separate terminal sessions (tmux, multiple termilas, terminal tabs... whatever you like), first run: 
```
    MIX_ENV=dev iex --name dev@127.0.0.1 -S mix run
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
        MIX_ENV=dev iex --name dev@127.0.0.1 -S mix run

node2:
        MIX_ENV=dev2 iex --name dev2@127.0.0.1 -S mix run
```
Now, try calling Riax.join('dev2@127.0.0.1') from terminal 1. Now,
Riax.ring_status will change to something like this:
``` 
iex(dev@127.0.0.1)7> Riax.ring_status
==================================== Nodes ====================================
Node a: 2 (  3.1%) dev@127.0.0.1
Node b: 62 ( 96.9%) dev2@127.0.0.1
==================================== Ring =====================================
babb|abbb|bbbb|bbbb|bbbb|bbbb|bbbb|bbbb|bbbb|bbbb|bbbb|bbbb|bbbb|bbbb|bbbb|bbbb|
```
Eventually (a minute, give or take) it should reach 50% on each node.
That's the handoff working.
## Tutorial:
## Use Case:
* I've mentioned this use case before, but let's go over it again: 
- We have several, or one relatively big file that we want
to provide (a dataset, for example)
- The file, or files, are not fit to be stored in memory due to its/their 
size.
- We want to avoid disk reading whenever we can, and achieve
high availability.
- We can scale horizontally and divide said file.
- This is where Riak comes in.
## Solution:
* We're going to address this use case in this tutorial, 
with the help of Riak Core.
* The key thing here is that we can use several Riak Nodes to offer an
in memory key-value storage. If we need more memory to store what we need,
we can add another node to our cluster and Riak Core will handle the 
details for us, provided we have an implemented VNode.
#### Creating project.
- Let's create a new mix project: `mix new my_cluster` for this, and make sure
to follow the setup steps from above (if you don't have a config folder, just
create it), and use the VNode I mention.
- Also, add this module under lib/riax_api.ex, which we'll use as an API to communicate with the VNode:
```elixir
defmodule Riax.API do
  def put(key, value) do
    Riax.sync_command(key, {:put, {key, value}})
  end

  def put(key, value, :no_log) do
    Riax.sync_command(key, {:put, :no_log, {key, value}})
  end

  def get(key) do
    Riax.sync_command(key, {:get, key})
  end

  def keys() do
    Riax.coverage_command(:keys)
  end

  def clear() do
    Riax.coverage_command(:clear)
  end

  def values() do
    Riax.coverage_command(:values)
  end

  def ring_status() do
    {:ok, ring} = :riak_core_ring_manager.get_my_ring()
    :riak_core_ring.pretty_print(ring, [:legend])
  end

  def ping() do
    ping(:os.timestamp())
  end

  def ping(key) do
    Riax.sync_command(key, {:ping, key})
  end
end
```

Each function is to communicate with our VNode that acts as a key-value 
store, note this function:

```elixir
def handle_command({:put, :no_log, {k, v}}, _sender, state = %{data: data}) do
  new_data = Map.put(data, k, v)
  {:reply, :ok, %{state | data: new_data}}
end
```
It's just to store a key-value pair, but it does not log it, as to make it 
faster.

Also, note the `keys/0` and `values/0`. They're coverage commands, that means
that they run in every node, each node returns a different answer.
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
* Now, let's start iex with a memory limit of 512 MB: `iex --erl "+MMsco true +MMscs 512 +Musac false"` 
``` elixir
    iex(1)> file = File.read!("mbsa.csv.zip") 
    ** (File.Error) could not read file "mbsa.csv.zip": not enough memory
        (elixir 1.13.0) lib/file.ex:355: File.read!/1
```
Working as intended: we tried to load a 1GB+ file while only having 512MB available.

- The unzipped CSV has a size of 8.5 GB, once stored in memory, 
so let's give each node 3GB of memory. This brings up an interesting result,
since Riak scales horizontally easily, this kind of use case is a perfect fit
for Riak: we can add more nodes to distribute the file easily.

```makefile
node1_limited:
    MIX_ENV=dev iex --erl "+MMsco true +MMscs 3000" --name dev@127.0.0.1 -S mix run
node2_limited:
    MIX_ENV=dev2 iex --erl "+MMsco true +MMscs 3000" --name dev2@127.0.0.1 -S mix run
node3_limited:
    MIX_ENV=dev3 iex --erl "+MMsco true +MMscs 3000" --name dev3@127.0.0.1 -S mix run
```
- You're going to need another config file: config/dev3.exs:
```elixir
import Config

config :riak_core,
node: 'dev3@127.0.0.1',
web_port: 8498,
handoff_port: 8499,
ring_state_dir: 'ring_data_dir_3',
platform_data_dir: 'data_3',
  schema_dirs: ['deps/riax/priv/' ]

``` 
- Try running each node and joining them with Riax.join, like in the setup. 
### Setting up csv.
#### Storing:
Let's use NimbleCsv (it's maintained by José Valim so it must be good) to read our file, add  this to your dependencies in mix.exs
```elixir
{:nimble_csv, "~> 1.1"}
```
-  Let's add to the lib/my_cluster.ex the following functions:
```elixir
defmodule CSVSetup do
  alias NimbleCSV.RFC4180, as: CSV

  def distribute_csv(path) do
    :rpc.multicall(CSVSetup, :store_csv, [path])
  end

  def store_csv(csv) do
    curr_node = node()

    csv
    |> File.stream!(read_ahead: 100_000)
    |> CSV.parse_stream()
    |> Stream.with_index()
    |> Stream.each(fn {[date, text, sentiment], indx} ->
      case Riax.preferred_node_name(indx) do
        ^curr_node ->
          # Date, text and sentiment are the 3 columns
          # that our example CSV of tweets has.
          Riax.API.put(indx, %{date: date, text: text, sentiment: sentiment}, :no_log)

        _ ->
          nil
      end
    end)
    |> Stream.run()
  end
end
```
- `distribute_csv/1` receives a path to a csv file,
and tells each running Riak Node (the ones joined using  :riak_core.join/1) with the `:rpc` module (more about it [here](https://www.erlang.org/doc/man/rpc.html)) to execute the `store_csv/1` function.
- `store_csv/1` indexes every row of the CSV and uses
them as keys for storing each row. So we end up with an index -> row mapping. We only store the index row pair if the index key belongs to the running node partition. We use `put/3` without logging because we know what we're storing.

### Reading CSV:
- Now that we have everything in place, lets run 3 VNodes in separate terminals,
using the make targets.
- On dev2 an dev3, run this `Riax.ring_join(dev@127.0.0.1)`.
Keep in mind that each node will remember who it has joined, so 
you don't have to do this every time you start the nodes.
- Run `Riax.ring_status` and wait a minute, you'll see that the key-space
is evenly distributed between the 3 nodes.
- Now, on any of the 3 nodes. Remember the csv we downloaded a few steps above?
Get its path, and run the following
```elixir
iex> pat
h = "/Path/to/mbsa.csv"
iex> MyCluster.distribute_csv(path)
```
Wait a bit, the terminal on which you ran the distribute_csv function will not
probably answer any commands until it stops reading the CSV
and then, you can try to get any row of the CSV with Riax.get(number).
Like this:
```elixir
  iex(dev@127.0.0.1)17> Riax.API.get(100)
  %{
  date: "2019-05-27",
  sentiment: "Positive",
  text: "Arkada?lar..Biz,bu milletin aklõ olan kesimine H?TAP ediyoruz.\n\n#DOLAR\n#DolarTL\n#bist\n#bist100 \n#usdtry\n#USDTRY\n#XU100 \n#???????????????? 2012\n#doge #dogeusd\n#btc #btcusd\nYTD"
  }
```
### Visualizing Results:
- Now that we have the data, let's show it. Stop the nodes and add scribe to your deps:
```elixir
    # mix.exs
    defp deps do
      [
        {:riax, ">= 0.1.0", github: "lambdaclass/elixir_riak_core", branch: "main"},
        {:scribe, "~> 0.10"}
      ]
    end
```
- On your MyCluster module, add this function:
```elixir
def print_data(page) do
  data =
    Enum.map(
      (page * 10)..(page * 10 + 10),
      fn indx ->
        # Get on which Virtual Node indx is stored
        node = Riax.preferred_node_name(indx)
        tweet = Riax.API.get(indx)
        Map.merge(tweet, %{node: node})
      end
    )

  Scribe.print(data)
end
```
- Set up the nodes again and read the CSV.
- Here we're printing the CSV rows on batches of 10 elements, try for example:
`MyCluster.print_data(10)`
