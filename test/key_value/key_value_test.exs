defmodule Riax.KeyValueTests do
  use ExUnit.Case, async: false

  setup_all do
    %{node1: node1, node2: node2, node3: node3} = setup_nodes()

    configure_node(node1)
    configure_node(node2)
    configure_node(node3)

    on_exit(fn ->
      "./data/test" |> Path.expand() |> File.rm_rf!()
    end)

    %{node1: node1, node2: node2, node3: node3}
  end

  describe "Test Nodes Health" do
    test "Check Cluster Setup", %{node1: node1, node2: node2, node3: node3} do
      assert node1 == :"dev1@127.0.0.1"
      assert node2 == :"dev2@127.0.0.1"
      assert node3 == :"dev3@127.0.0.1"
    end

    test "Ring Status", %{node1: node1, node2: node2, node3: node3} do
      :ok = :rpc.call(node1, Riax, :ring_status, [])
      :ok = :rpc.call(node2, Riax, :ring_status, [])
      :ok = :rpc.call(node3, Riax, :ring_status, [])
    end

    test "Join nodes", %{node1: node1, node2: node2, node3: node3} do
      :ok = :rpc.call(node1, Riax, :join, ['manager@127.0.0.1'])
      :ok = :rpc.call(node2, Riax, :join, [node1])
      :ok = :rpc.call(node3, Riax, :join, [node1])
    end
  end

  describe "Riax with Key Value Implementation " do
    test "Sync Command", _ do
      {:pong, 11, _node, _} = Riax.sync_command(:key, "riax", {:ping, 10})
    end
    test "ASync Command", _ do
      :ok = Riax.async_command(:key, "riax", {:put, {:key, :value}})
      :value = Riax.async_command(:key, "riax", {:get, :key})
    end
    test "Cast Command", _ do
      Riax.cast_command(:key, "riax", {:put, {:key, :value}})
      :value = Riax.async_command(:key, "riax", {:get, :key})
    end
  end

  defp setup_nodes() do
    :ok = LocalCluster.start()
    [node1, node2, node3] = LocalCluster.start_nodes("dev", 3)
    %{node1: node1, node2: node2, node3: node3}
  end

  # Given a node name, set it up for use with Riak Core.
  defp configure_node(node = :"dev1@127.0.0.1"), do: configure_node(node, 8199, 8198)
  defp configure_node(node = :"dev2@127.0.0.1"), do: configure_node(node, 8299, 8298)
  defp configure_node(node = :"dev3@127.0.0.1"), do: configure_node(node, 8399, 8398)

  defp configure_node(node, web_port, handoff_port) do
    :ok =
      :rpc.call(node, :application, :set_env, [
        :riak_core,
        :ring_state_dir,
        "./data/test/#{Atom.to_string(node)}" |> String.to_charlist()
      ])

    :ok = :rpc.call(node, :application, :set_env, [:riax, :vnode, Riax.VNode.Impl])
    :ok = :rpc.call(node, :application, :set_env, [:riak_core, :node, node])

    :ok =
      :rpc.call(node, :application, :set_env, [
        :riak_core,
        :platform_data_dir,
        "./data/test/#{Atom.to_string(node)}" |> String.to_charlist()
      ])

    :ok = :rpc.call(node, :application, :set_env, [:riak_core, :web_port, web_port])
    :ok = :rpc.call(node, :application, :set_env, [:riak_core, :handoff_port, handoff_port])

    {:ok, [:riak_core, :riax]} = :rpc.call(node, :application, :ensure_all_started, [:riax])
  end
end
