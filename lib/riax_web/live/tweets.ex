defmodule RiaxWeb.Tweetslive do
  use Phoenix.LiveView

  def mount(%{"num" => num}, _session, socket) when num > 0 do
    {num, ""} = Integer.parse(num, 10)

    tweets =
      Enum.map((num * 10)..(num * 10 + 10), fn x -> {Riax.preferred_node_name(x), Riax.get(x)} end)

    {:ok,
     assign(
       socket,
       tweets: tweets
     )}
  end

  def render(assigns) do
    ~L"""
    <h1>Tweets</h1>
    <table>
    <tbody>
    <%= for {node, %{date: date, text: text, sentiment: sentiment}} <- @tweets do %>
        <tr>
        <div style="text-overflow: ellipsis">
        <td >
        <%= "Node: " <> Atom.to_string(node) %>
        <br>
        <%= "Date: " <> date %>
        <br>
        <%= "Text: " <> text %>
        <br>
        <%= "Sentiment: " <> sentiment %>
        </td>
        </div>
        </tr>
    <%  end %>
    </tbody>
    </table>
    """
  end
end
