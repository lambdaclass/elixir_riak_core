node1:
	MIX_ENV=dev1 iex  --name dev1@127.0.0.1 -S mix run

node2:
	MIX_ENV=dev2 iex --name dev2@127.0.0.1 -S mix run

node3:
	MIX_ENV=dev3 iex --name dev3@127.0.0.1 -S mix run

phoenix:
	MIX_ENV=dev iex --name phoenix@127.0.0.1 -S mix phx.server

VM_ARGS := "+MMsco true +MMscs 2500"

node1_limited:
	MIX_ENV=dev1 iex --erl $(VM_ARGS) --name dev1@127.0.0.1 -S mix run
node2_limited:
	MIX_ENV=dev2 iex --erl $(VM_ARGS) --name dev2@127.0.0.1 -S mix run
node3_limited:
	MIX_ENV=dev3 iex --erl $(VM_ARGS) --name dev3@127.0.0.1 -S mix run
phoenix_limited:
	MIX_ENV=dev iex --erl $(VM_ARGS) --name phoenix@127.0.0.1 -S mix phx.server
