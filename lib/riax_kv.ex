defmodule Riax.KV do
  @moduledoc """
  Riax Key-Value API
  """
  @doc """
  Store a value tied to a key
  """
  def put(key, value) do
    Riax.sync_command(key, {:put, {key, value}})
  end

  @doc """
  Store a value tiead to a key, but do not
  log it.

  Ideal to store fast.
  """
  def put(key, value, :no_log) do
    Riax.sync_command(key, {:put, :no_log, {key, value}})
  end

  @doc """
  Retrieve a key's value
  """
  def get(key) do
    Riax.sync_command(key, {:get, key})
  end

  @doc """
  Retrieve keys
  """
  def keys() do
    Riax.coverage_command(:keys)
  end

  @doc """
  Set an empty data state for every available VNode
  """
  def clear() do
    Riax.coverage_command(:clear)
  end

  @doc """
  Return every value of every available VNode
  """
  def values() do
    Riax.coverage_command(:values)
  end

  @doc """
   :pong
  """
  def ping(key) do
    Riax.sync_command(key, {:ping, key})
  end
end
