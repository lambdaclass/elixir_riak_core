defmodule RiaxWeb.APIView do
  use RiaxWeb, :controller

  def render("index.json", %{conn: %{assigns: %{tweet: tweet}}}) do
    IO.inspect(tweet, label: :PARAMS)
    tweet
  end
end
