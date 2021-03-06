# Riax ![Build](https://github.com/lambdaclass/elixir_riak_core/actions/workflows/github-actions.yml/badge.svg)

Riax is an Elixir wrapper for [Riak Core](https://github.com/basho/riak_core). 
Riak Core is a building block for distributed and scalable systems
in the form of an Erlang Framework.

To learn more about Riak you can check the  [Riak Core](#riak-core) and [useful links section](#useful-links) sections.
To learn more about Riax, check [the setup](https://lambdaclass.github.io/elixir_riak_core/setup.html), [the tutorial](https://lambdaclass.github.io/elixir_riak_core/tutorial.html) or [the API Reference](https://lambdaclass.github.io/elixir_riak_core/api-reference.html).

If you want to set it up with Erlang, we also have an [up-to-date (OTP 25)
tutorial](https://github.com/lambdaclass/riak_core_tutorial). 
## Use example

```elixir
iex(dev1@127.0.0.1)1> #### Check the Ring Status
iex(dev1@127.0.0.1)2> Riax.ring_status
==================================== Nodes ====================================
Node a: 64 (100.0%) dev1@127.0.0.1
==================================== Ring =====================================
aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|aaaa|
:ok
iex(dev1@127.0.0.1)3> #### Join an already running Node
iex(dev1@127.0.0.1)4> Riax.join('dev2@127.0.0.1')
13:51:21.258 [debug] Handoff starting with target: {:hinted, {913438523331814323877303020447676887284957839360, :"dev2@127.0.0.1"}}
iex(dev1@127.0.0.1)5> #### Send a command to a VNode
iex(dev1@127.0.0.1)6> Riax.sync_command(1, "riax", {:ping, 1})
    13:13:08.004 [debug] Received ping command!
    {:pong, 2, :"dev1@127.0.0.1", 822094670998632891489572718402909198556462055424}
```

## Installation

Add Riax to your dependencies:
```elixir
defp deps do
  [
    {:riax, ">= 0.1.0", github: "lambdaclass/elixir_riak_core", branch: "main"}
  ]
end
```
And follow [the setup](https://lambdaclass.github.io/elixir_riak_core/setup.html)

## Riak Core

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

## Use cases
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
hash it and assign it to a Virtual Node. Riak fits really well here as it
scales easily horizontally.
This last use case is actually explained below.

## More about Hashing and VNodes
Before performing an operation, a hashing function is applied to some data, a
key. The key hash will be used to decide which node in the cluster should be
responsible for executing the operation. The range of possible values the key
hash can take (the keyspace, usually depicted as a ring), is partitioned in
equally sized buckets, which are assigned to Virtual Vodes.

![The Ring](https://raw.githubusercontent.com/lambdaclass/riak_core_tutorial/master/ring.png)

Virtual Nodes share what is called a keyspace.
The number of VNodes is fixed at cluster creation and a given hash value will
always belong to the same partition (i.e. the same VNode). The VNodes in turn
are evenly distributed across all available physical nodes. Note this
distribution isn't fixed as the keyspace partitioning is: the VNode distribution
can change if a physical node is added to the cluster or goes down.

After this, be sure to check [the tutorial](https://lambdaclass.github.io/elixir_riak_core/tutorial.html)
to see this in action
## Useful links
* [Introducing Riak Core](http://basho.com/posts/business/introducing-riak-core/)
* [Riak Core Wiki](https://github.com/basho/riak_core/wiki)
* [Masterless Distributed Computing with Riak Core](http://www.erlang-factory.com/upload/presentations/294/MasterlessDistributedComputingwithRiakCore-RKlophaus.pdf)
* Ryan Zezeski's "working" blog:
  [First, multinode](https://github.com/rzezeski/try-try-try/tree/master/2011/riak-core-first-multinode) and
  [The vnode](https://github.com/rzezeski/try-try-try/tree/master/2011/riak-core-the-vnode)
* [Little Riak Core Book](https://marianoguerra.github.io/little-riak-core-book/)
* riak_core in Elixir:
  [Part I](https://medium.com/@GPad/create-a-riak-core-application-in-elixir-part-1-41354c1f26c3),
  [Part II](https://medium.com/@GPad/create-a-riak-core-application-in-elixir-part-2-88bdec73f368),
  [Part III](https://medium.com/@GPad/create-a-riak-core-application-in-elixir-part-3-8bac36632be0),
  [Part IV](https://medium.com/@GPad/create-a-riak-core-application-in-elixir-part-4-728512ece224) and
  [Part V](https://medium.com/@GPad/create-a-riak-core-application-in-elixir-part-5-86cd9d2c6b92)
* [A Gentle Introduction to Riak Core](http://efcasado.github.io/riak-core_intro)
* Understanding Riak Core:
  [Handoff](http://basho.com/posts/technical/understanding-riak_core-handoff/),
  [Building Handoff](http://basho.com/posts/technical/understanding-riak_core-building-handoff/)
  and
  [The visit fun](http://basho.com/posts/technical/understanding-riak_core-visitfun/)
* [udon_ng](https://github.com/mrallen1/udon_ng) example application.
