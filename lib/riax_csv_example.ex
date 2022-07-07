defmodule Riax.CSV do
  alias NimbleCSV.RFC4180, as: CSV

  @moduledoc """
  Functions to read and distribute CSV among
  Virtual Nodes for the example setup.
  """
  @doc """
  Distribute the given path's CSV among Riak Nodes,
  by storing it as row_number -> row values mapping.
  """
  def distribute_csv(path) do
    :rpc.multicall(Riax.CSV, :store_csv, [path])
  end

  @doc """
  Stores a CSV in the running node's assigned ring partitions.
  Each of the CSV's rows are stored using the row's index number as key.
  Eg. If I have "100" as key and the current ring status
  determines that "100" should end up on Node 2, and I'm
  running this function on Node 1, it'll simply ignore that key.
  """
  def store_csv(csv) do
    curr_node = node()

    csv
    |> File.stream!(read_ahead: 100_000)
    |> CSV.parse_stream()
    |> Stream.with_index()
    |> Stream.each(fn {[date, text, sentiment], indx} ->
      case Riax.preferred_node_name(indx) do
        ^curr_node ->
          # Date, text and sentiment are the 3 columns
          # that our example CSV of tweets has.
          Riax.put(indx, %{date: date, text: text, sentiment: sentiment}, :no_log)

        _ ->
          nil
      end
    end)
    |> Stream.run()
  end
end
