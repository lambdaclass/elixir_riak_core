defmodule RiaxWeb.Counterlive do
  use Phoenix.LiveView

  def mount(_, _session, socket) do
    counters = setup_counters()

    {:ok,
     assign(
       socket,
       Map.merge(counters, %{node_1: "", node_2: "", node_3: ""})
     )}
  end

  def render(assigns) do
    ~L"""
    <h1>Working Counter from Phoenix + Riak!</h1>
    Counter 1, with key: <%= @counter_1 |> elem(0) %>, connected to: <%= @node_1 %>

    </br>

    <%= @counter_1 |> elem(1) %>
    <button phx-click="inc_num">
    +
    </button>


    </br>

    Counter 2, with key: <%= @counter_2 |> elem(0) %>, connected to: <%= @node_2 %>
    </br>
    <%= @counter_2 |> elem(1) %>
    <button phx-click="inc_num_2">
    +
    </button>

    </br>
    Counter 3, with key: <%= @counter_3 |> elem(0) %>, connected to: <%= @node_3 %>
    </br>
    <%= @counter_3 |> elem(1) %>
    <button phx-click="inc_num_3">
    +
    </button>
    </div>
    """
  end

  def handle_event("inc_num", _value, socket) do
    {key, value} = socket.assigns.counter_1
    Riax.put(key, value + 1)
    {:noreply, assign(socket, counter_1: {key, Riax.get(key)})}
  end

  def handle_event("inc_num_2", _value, socket) do
    {key, value} = socket.assigns.counter_2
    Riax.put(key, value + 1)
    {:noreply, assign(socket, counter_2: {key, Riax.get(key)})}
  end

  def handle_event("inc_num_3", _value, socket) do
    {key, value} = socket.assigns.counter_3
    Riax.put(key, value + 1)
    {:noreply, assign(socket, counter_3: {key, Riax.get(key)})}
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

  defp random_string() do
    for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdefghijklmñopqrstuwxyz')>>
  end

  defp setup_counters() do
    [:counter_1, :counter_2, :counter_3]
    |> Map.new(fn counter ->
      key = random_string()
      value = get_value(key)
      {counter, {key, value}}
    end)
  end
end
