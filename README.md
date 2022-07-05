# Riax
- Simple Riak Core use case example.
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
  * Now, let's start iex with the memory limit: `iex --erl "+MMsco true +MMscs 512 +Musac false"` 
    ``` elixir
    iex(1)> file = File.read!("mbsa.csv.zip") 
    ** (File.Error) could not read file "mbsa.csv.zip": not enough memory
        (elixir 1.13.0) lib/file.ex:355: File.read!/1
    ```
  * Working as intended, we tried to load a 1GB+ file while only having 512MB
    available.
  * The unzipped CSV has a size of 3.3 GB, give or take, so let's use 3 nodes,
    with 1300 MB each, so let's use this makefile:

``` makefile
node1_limited:
	MIX_ENV=dev1 iex --erl "+MMsco true +MMscs 1300" --name dev1@127.0.0.1 -S mix run
node2_limited:
	MIX_ENV=dev2 iex --erl "+MMsco true +MMscs 1300" --name dev2@127.0.0.1 -S mix run
node3_limited:
	MIX_ENV=dev3 iex --erl "+MMsco true +MMscs 1300" --name dev3@127.0.0.1 -S mix run
```

### Setting up csv.
* Let's add new function to our Riak API. It will
  take our CSV file and distribute it among our running Nodes.
``` elixir
  def setup_csv(path) do
    File.stream!(path)
    |> CSV.decode(headers: true)
    |> Stream.with_index()
    |> Stream.map(fn {val, indx} -> {indx, val} end)
    |> Stream.each(fn {indx, val} -> sync_command(indx, {:put, :no_log, {indx, val}}) end)
  end
```
 We use Stream instead of Enum to not run out of memory.
* The result of this will be an Index -> CSV-Row mapping across our Nodes.
  We need another function, to handle our sync_command call: 

 ``` elixir
  def handle_command({:put, :no_log, {k, v}}, _sender, state = %{data: data}) do
    new_data = Map.put(data, k, v)
    {:reply, :ok, %{state | data: new_data}}
  end
 ```

* Now that we have everything in place, we have to do the following: 
  1. Start the 3 nodes on different terminals using  `make nodeN_limited_`
  2. Join the nodes with `:riak_core.join(node@host)`.
  3. Run the Riax.setup_csv/1 function, this might take a while, although the
     terminal where you ran this function will probably stay locked you can use
     the other nodes to check that the CSV rows are being stored.
  4. Try to use, for example, Riax.get/1 to get a CSV row.
### Visualizing data:
* PLACEHOLDER:


