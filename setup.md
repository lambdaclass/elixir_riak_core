# Setup
We recommend to use Elixir 1.13 and OTP 25.

## Single node:
1. First, add Riax as a dependency to your mix.exs
```elixir
    defp deps do
        [
        {:riax, ">= 0.1.0", github: "lambdaclass/elixir_riak_core", branch: "main"}
        ]
    end
```
(It's not available on hex.pm as every dependency of Riak Core, and Riak itself,
is hosted on Github. And hex.pm does not allow to upload packages with git dependencies)
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
    # further in the Riax.VNode doc.
    handoff_port: 8199,
    # Where to save this node's ring
    # state
    ring_state_dir: 'ring_data_dir_1',
    platform_data_dir: 'data_1',
    # This is a config file for Riak Core,
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
```elixir
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
