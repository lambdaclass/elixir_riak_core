defmodule Riax.VNode.Impl do
  use Riax.VNode

  def command({:ping, v}, _sender, state = %{partition: partition}) do
        Logger.debug("Received ping command!", state)
        {:reply, {:pong, v + 1, node(), partition}, state}
  end
end
