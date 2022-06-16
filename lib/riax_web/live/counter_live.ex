defmodule RiaxWeb.Counterlive do
  use Phoenix.LiveView

  defp get_values() do
  end

  def mount(_, _session, socket) do
    value_1 = get_value(:counter_1)
    node_1 = Riax.get_key_node(:counter_1) |> IO.inspect(label: :get_key_result)
    value_2 = get_value(:counter_2)
    node_2 = Riax.get_key_node(:counter_2)
    value_3 = get_value(:counter_3)
    node_3 = Riax.get_key_node(:counter_3)

    {:ok,
     assign(socket,
       msg: "Hi from Liveview",
       counter_1: value_1,
       counter_2: value_2,
       counter_3: value_3,
       node_1: node_1,
       node_2: node_2,
       node_3: node_3
     )}
  end

  def render(assigns) do
    ~L"""
    <h1>Working Counter from Phoenix + Riak!</h1>
    Counter 1, Connected to: <%= @node_1 %>

    </br>

    <%= @counter_1 %>
    <button phx-click="inc_num">
    +
    </button>


    </br>

    Counter 2, Connected to:
    </br>
    <%= @counter_2 %>
    <button phx-click="inc_num_2">
    +
    </button>

    </br>
    Counter 3, Connected to:
    </br>
    <%= @counter_3 %>
    <button phx-click="inc_num_3">
    +
    </button>
    </div>
    """
  end

  def handle_event("inc_num", _value, socket) do
    new_value = socket.assigns.counter_1 + 1
    Riax.put(:counter_1, new_value)
    {:noreply, assign(socket, counter_1: new_value)}
  end

  def handle_event("inc_num_2", _value, socket) do
    new_value = socket.assigns.counter_2 + 1
    Riax.put(:counter_2, new_value)
    {:noreply, assign(socket, counter_2: socket.assigns.counter_2 + 1)}
  end

  def handle_event("inc_num_3", _value, socket) do
    new_value = socket.assigns.counter_3 + 1
    Riax.put(:counter_3, new_value)
    {:noreply, assign(socket, counter_3: socket.assigns.counter_3 + 1)}
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    {:noreply, assign(socket, msg: key)}
  end

  defp get_value(key) do
    case Riax.get(key) do
      :not_found ->
        Riax.put(key, 0)
        get_value(key)

      val ->
        val
    end
  end
end
