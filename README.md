# Riax
A tutorial on how to cache files over several Riak Nodes.
## Quick start:
  * Install dependencies with `mix deps.get`
  * Start the Riak Nodes with `make node1`, `make node2`, `make node3`, this will
    have to be done on separate terminals, or using something like Tmux.
  * Now, try to join the nodes using `:riak_core.join(node@host)` and use the Riax
    module as an API connecting to each Node.
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
