defmodule Adjust do
  require Logger

  # number of entries
  @elements_to_insert 1_000_000

  # bulk insert
  @multi_value 10

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
  Populate source table with n Task
  """
  def fill_source(n \\ 100) do
    chunk_size = Integer.floor_div(@elements_to_insert, n)

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
    remain_element = rem(end_val - start_val + 1, @multi_value)

    with {:ok, conn} <- Adjust.Repo.connect("foo"),
         {:ok, query_remain} <- Adjust.Repo.get_source_query(conn, remain_element),
         {:ok, query_multi} <- Adjust.Repo.get_source_query(conn, @multi_value) do
      start_val..end_val
      |> Enum.chunk_every(@multi_value)
      |> Enum.map(fn xs ->
        multi_insert_into(
          conn,
          select_query(
            {query_multi, query_remain},
            length(xs) == @multi_value
          ),
          xs
        )
      end)

      # destroy statements and close connection
      Adjust.Repo.destroy_query(conn, query_multi)
      Adjust.Repo.destroy_query(conn, query_remain)
      Adjust.Repo.close(conn)
    else
      _ ->
        Logger.error("fill_source: is not possible to populate source")
        :error
    end
  end

  defp select_query({a, _b}, true), do: a
  defp select_query({_a, b}, false), do: b

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
