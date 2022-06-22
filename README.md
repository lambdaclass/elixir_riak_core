# Riax

## Starting:
  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `make phoenix`, this will set up both a Phoenix and Riak Node.
  * Start the Riak Nodes with `make node1`, `make node2`, `make node3`, this will
    have to be done on separate terminals, or using something like Tmux.
  * Now, try to join the nodes using `:riak_core.join(node@host)` and use the Riax
    module as an API connecting to each Node.
## Simple Example:
- You can visit [`localhost:4003`](http://localhost:4003/) from your browser
  to see a simple example running.
