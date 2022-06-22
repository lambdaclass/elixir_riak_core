defmodule RiaxWeb.PageController do
  use RiaxWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
