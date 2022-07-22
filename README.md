# Riax ![Build](https://github.com/lambdaclass/elixir_riak_core/actions/workflows/github-actions.yml/badge.svg)

Riax is an Elixir wrapper for Riak Core. 
Riak Core is a distributed systems framework, written in Erlang.
You can think of it as a building block for distributed and scalable systems.
Check the 
To learn more, you can check the useful links section in the repo linked above, and check the 
[docs](https://lambdaclass.github.io/elixir_riak_core/api-reference.html) for more.
If you want to set it up with Erlang, we also have an [up-to-date (OTP 25)
tutorial](https://github.com/lambdaclass/riak_core_tutorial). 
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
hash it and assign it to a Virtual Node. Riak fits really well here as it
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
