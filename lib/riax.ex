defmodule Riax do
  def put(key, value) do
    sync_command(key, {:put, {key, value}})
  end

  def get(key) do
    sync_command(key, {:get, key})
  end

  def keys() do
    sync_command(:key, :keys)
  end
  end
end
