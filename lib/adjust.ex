defmodule Adjust do
  require Logger

  # number of entries
  @elements_to_insert 1_000_000

  @doc """
   Initialize the DBs:
     create two tables:
     - "source" into :foo DB
     - "dest" into :bar DB
  """
  def init() do
    with {:ok, conn} <- Adjust.Repo.connect(),
         {:ok, _result} <- Adjust.Repo.create_db(conn, "foo"),
         {:ok, _result} <- Adjust.Repo.create_db(conn, "bar") do
      Logger.info("DBs created")
      create_tables()
    else
      _ -> Logger.error("is not possibile to initialize DB")
    end
  end

  @doc """
  Populate source table (using multiple Tasks)
  """
  def fill_source() do
    chunk_size = Integer.floor_div(@elements_to_insert, 100)

    chunker(1, @elements_to_insert, chunk_size)
    |> Enum.map(fn chunk ->
      Task.async(fn ->
        insert_into(chunk)
        :ok
      end)
    end)
    |> Enum.map(&Task.await(&1, :infinity))

    :ok
  end

  @doc """
  Copy source table into dest
  """
  def copy_to_dest() do
    with {:ok, conn_foo} <- Adjust.Repo.connect("foo"),
         {:ok, conn_bar} <- Adjust.Repo.connect("bar") do
      # use stream
      Postgrex.transaction(conn_foo, fn(conn_in) ->
        query = Postgrex.prepare(conn_in, "", "COPY source TO STDOUT")
        stream_in = Postgrex.stream(conn_in, query, [])

        Postgrex.transaction(conn_bar, fn(conn_out) ->
          result_to_iodata = fn(%Postgrex.Result{rows: rows}) -> rows end
          stream_out = Postgrex.stream(conn_out, "COPY dest FROM STDIN", [])
          Enum.into(stream_in, stream_out, result_to_iodata)
        end)
      end)
    else
      _ -> Logger.error("is not possible COPY source in dest")
    end
  end

  ### PRIVATE ###

  defp create_tables() do
    with {:ok, conn_foo} <- Adjust.Repo.connect("foo"),
         {:ok, conn_bar} <- Adjust.Repo.connect("bar"),
         {:ok, _r} <- Adjust.Repo.create_table(conn_foo, "source"),
         {:ok, _r} <- Adjust.Repo.create_table(conn_bar, "dest") do
      Logger.info("table created")
    else
      _ -> Logger.error("is not possibile to create table")
    end
  end

  defp insert_into({start_val, end_val}) do
    concurrent_insert = 10

    with {:ok, conn} <- Adjust.Repo.connect("foo"),
         {:ok, query} <- Adjust.Repo.get_source_query(conn, concurrent_insert) do
      start_val..end_val
      |> Enum.chunk_every(concurrent_insert)
      |> Enum.map(fn xs ->
        multi_insert_into(conn, query, xs)
      end)

      # destroy statement and close connection
      Adjust.Repo.destroy_query(conn, query)
      Adjust.Repo.close(conn)
    else
      _ ->
        Logger.error("fill_source: is not possible to populate source")
        :error
    end
  end

  defp multi_insert_into(conn, query, xs) do
    Adjust.Repo.insert_into_source(conn, query, calc(xs))
    :ok
  end

  defp chunker(start_value, end_value, _size) when start_value > end_value, do: []

  defp chunker(start_value, end_value, size) when start_value < end_value and size > 0 do
    [{start_value, start_value + size - 1} | chunker(start_value + size, end_value, size)]
  end

  defp calc([]), do: []

  defp calc([x | xs]) do
    [x, rem(x, 3), rem(x, 5)] ++ calc(xs)
  end
end
