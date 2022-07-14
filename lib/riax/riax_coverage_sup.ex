defmodule Riax.Coverage.Sup do
  @moduledoc """
  Supervises and starts the Coverage State Machine.
  """
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end

  def start_fsm(args) when is_list(args) do
    fsm_spec = %{
      id: :undefined,
      start: {Riax.Coverage.Fsm, :start_link, args},
      restart: :temporary,
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, fsm_spec)
  end
end
