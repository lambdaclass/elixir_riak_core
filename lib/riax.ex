defmodule Riax do
  def put(key, value) do
    :rpc.call(node(), :rc_example, :put, [key, value])
  end

  def get(key) do
    :rpc.call(node(), :rc_example, :get, [key])
  end

  def keys() do
    :rpc.call(node(), :rc_example, :keys, [])
  end

  def get_key_node(key) do
    case find_key(key) |> IO.inspect(label: :keys) do
      {_hash, node, _} -> node
      _ -> :no_key
    end
  end

  defp find_key(key) do
    {:ok, keys} = keys()

    keys
    |> Enum.find(fn tuple ->
      case tuple do
        {_hash, node, ^key} -> true
        _ -> false
      end
    end)
  end
end

