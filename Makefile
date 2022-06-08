node1:
	MIX_ENV=dev1 iex --name dev1@127.0.0.1 -S mix run

node2:
	MIX_ENV=dev2 iex --name dev2@127.0.0.1 -S mix run

node3:
	MIX_ENV=dev3 iex --name dev3@127.0.0.1 -S mix run

phoenix:
	iex -S mix phx.server
