defmodule RiaxWeb.PageController do
  use RiaxWeb, :controller
  @behaviour :riak_core_vnode

  def index(conn, _params) do
    {:pong, ping_1} = :rpc.call(:"dev1@127.0.0.1", :rc_example, :ping, [])
    {:pong, ping_2} = :rpc.call(:"dev2@127.0.0.1", :rc_example, :ping, [])
    {:pong, ping_3} = :rpc.call(:"dev3@127.0.0.1", :rc_example, :ping, [])

    render(conn, "index.html", %{
      node_1: ping_1,
      node_2: ping_2,
      node_3: ping_3,
      id: 123
    })
  end
end
