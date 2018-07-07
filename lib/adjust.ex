defmodule Adjust do
  require Logger

  @elements_to_insert 1_000_000
  @multi_value        10

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
    chunker(1, @elements_to_insert, Integer.floor_div(@elements_to_insert, n))
    |> Enum.map(fn chunk ->
      Task.async(fn ->
        insert_into(chunk)
        :ok
      end)
    end)
    |> Enum.map(&(Task.await(&1, :infinity)))
    :ok
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
    with {:ok, conn} <- Adjust.Repo.connect("foo"),
         {:ok, query_single} <- Adjust.Repo.get_source_query(conn),
         {:ok, query_multi}  <- Adjust.Repo.get_source_query(conn, @multi_value) do
      start_val..end_val
      |> Enum.chunk_every(@multi_value)
      |> Enum.map(fn xs ->
        case length(xs) do
          @multi_value ->
            multi_insert_into(conn, query_multi, xs, :many)
          _ ->
            multi_insert_into(conn, query_single, xs, :single)
        end
        :ok
      end)
      Adjust.Repo.destroy_query(conn, query_single)
      Adjust.Repo.destroy_query(conn, query_multi)
      Adjust.Repo.close(conn)
    else
      ex ->
        IO.inspect ex
        Logger.error("fill_source: is not possible to populate source")
        :error
    end
  end

  defp multi_insert_into(conn, query, xs, :many) do
    Adjust.Repo.insert_into_source(conn, query, calc(xs))
  end

  defp multi_insert_into(_conn, _query, [], :single), do: :ok
  defp multi_insert_into(conn, query, [x | xs], :single) do
    Adjust.Repo.insert_into_source(conn, query, [x, rem(x, 3), rem(x, 5)])
    multi_insert_into(conn, query, xs, :single)
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
