defmodule Riax.KeyValueTests do
  use ExUnit.Case

  describe "Test Riax via a Key-Value setup" do
    setup do
      %{node1: node1, node2: node2, node3: node3} = setup_nodes()
    end

    test "Check Cluster Setup", %{node1: node1, node2: node2, node3: node3} do
      assert node1 == :"dev1@127.0.0.1"
      assert node2 == :"dev2@127.0.0.1"
      assert node3 == :"dev3@127.0.0.1"
    end

    test "the truth", %{node1: node1} do
      config = [
        [
          node: node1,
          web_port: 8198,
          handoff_port: 8199,
          ring_state_dir: "/Users/fran/Programming/Elixir/elixir_riak_core/priv/",
          platform_data_dir: 'data_1',
          schema_dirs: ['priv']
        ]
      ]

      :ok =
        :rpc.call(node1, :application, :set_env, [
          :riak_core,
          :ring_state_dir,
          "./data/" |> String.to_charlist()
        ])

      :ok = :rpc.call(node1, :application, :set_env, [:riax, :vnode, Riax.VNode.Impl])
      :ok = :rpc.call(node1, :application, :set_env, [:riak_core, :node, node])

      :ok =
        :rpc.call(node1, :application, :set_env, [
          :riak_core,
          :platform_data_dir,
          "./data/" |> String.to_charlist()
        ])

      :ok = :rpc.call(node1, :application, :set_env, [:riak_core, :web_port, 8196])
      :ok = :rpc.call(node1, :application, :set_env, [:riak_core, :handoff_port, 8189])

      {:ok, [:riak_core, :riax]} = :rpc.call(node1, :application, :ensure_all_started, [:riax])
      :ok = :rpc.call(node1, Riax, :ring_status, [])
      # :ok =
      #   :rpc.call(node1, :application, :set_env, [
      #     :riak_core,
      #     :schema_dirs,
      #     ["/Users/fran/Programming/Elixir/elixir_riak_core/priv/riak_core.schema"]
      #   ])

      :ok = :rpc.call(node1, Riax, :ring_status, [])
    end
  end

  defp setup_nodes() do
    :ok = LocalCluster.start()
    [node1, node2, node3] = LocalCluster.start_nodes("dev", 3)
    %{node1: node1, node2: node2, node3: node3}
  end
end
