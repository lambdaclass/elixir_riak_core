node1:
	MIX_ENV=dev1 iex  --name dev1@127.0.0.1 -S mix run

node2:
	MIX_ENV=dev2 iex --name dev2@127.0.0.1 -S mix run

node3:
	MIX_ENV=dev3 iex --name dev3@127.0.0.1 -S mix run

phoenix:
	MIX_ENV=dev iex --name phoenix@127.0.0.1 -S mix phx.server

node1_limited:
	MIX_ENV=dev1 iex --erl "+MMsco true +MMscs 1500" --name dev1@127.0.0.1 -S mix run
node2_limited:
	MIX_ENV=dev2 iex --erl "+MMsco true +MMscs 1500" --name dev2@127.0.0.1 -S mix run
node3_limited:
	MIX_ENV=dev3 iex --erl "+MMsco true +MMscs 1500" --name dev3@127.0.0.1 -S mix run
