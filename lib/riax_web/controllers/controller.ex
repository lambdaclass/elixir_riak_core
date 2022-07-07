defmodule RiaxWeb.API do
  use RiaxWeb, :controller

  def index(conn, %{"num" => num}) do
    {num, ""} = Integer.parse(num)
    tweet = Riax.KV.get(num)
    render(conn, "index.json", tweet: tweet)
  end
end
