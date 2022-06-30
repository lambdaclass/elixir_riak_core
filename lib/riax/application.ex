defmodule Riax.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger
  use Application

  @nodes [
    :"dev1@127.0.0.1",
    :"dev2@127.0.0.1",
    :"dev3@127.0.0.1"
  ]
  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      RiaxWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Riax.PubSub},
      # Start the Endpoint (http/https)
      {RiaxWeb.Endpoint, name: Riax.Endpoint},
      # Start Riak's supervisor,
      # vnode: the vnode implementation,
      # coverage: the supervisor for the coverage.
      {Riax.Supervisor, vnode: Riax.VNode, coverage: Riax.Coverage.Sup}
    ]


    [:ok, :ok, :ok] = connect_nodes()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Riax.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp connect_nodes do
    phoenix_node = node()

    Enum.map(@nodes, fn node ->
      case :rpc.call(node, :riak_core, :join, [phoenix_node]) do
        {:error, :not_reachable} -> {:error, node}
        _ -> :ok
      end
    end)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RiaxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
