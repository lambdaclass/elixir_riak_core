defmodule RiaxWeb.APIView do
  use RiaxWeb, :controller

  def render("index.json", %{conn: %{assigns: %{tweet: tweet}}}) do
    tweet
  end
end
