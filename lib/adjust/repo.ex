defmodule Adjust.Repo do
  def connect(database \\ "postgres") do
    # todo: take it from conf
    Postgrex.start_link(
      hostname: "localhost",
      username: "postgres",
      password: "qwerty",
      database: database
    )
  end

  def close(conn), do: GenServer.stop(conn)

  @doc """
  Destroy a prepared query
  """
  def destroy_query(conn, query), do: Postgrex.close(conn, query)

  @doc """
  Create a DB with the given name
  """
  def create_db(conn, name) do
    Postgrex.query(conn, "CREATE DATABASE #{name}", [])
  end

  @doc """
  Create a Table, into a specific DB, with this schema:
    - a integer
    - b integer
    - c integer
  """
  def create_table(conn, table_name) do
    Postgrex.query(conn, "CREATE TABLE #{table_name} (a integer, b integer, c integer)", [])
  end

  @doc """
  Prepare the query on a given connectio.
  n_row is the number of multiple values (default: 1)
  """
  def get_source_query(conn, n_rows \\ 1) do
    Postgrex.prepare(conn, "source", "INSERT INTO source(a, b, c) VALUES #{values(1, n_rows)}")
  end

  def insert_into_source(conn, query, params) do
    Postgrex.execute(conn, query, params)
  end

  @doc """
    Copy Table A from DB A to Table B in DB B
  """
  def copy_to_dest([{:db, db_a}, {:table, table_a}], [{:db, db_b}, {:table, table_b}]) do
    with {:ok, conn_foo} <- Adjust.Repo.connect(db_a),
         {:ok, conn_bar} <- Adjust.Repo.connect(db_b) do
      # use stream
      Postgrex.transaction(conn_foo, fn(conn_in) ->
        {:ok, query} = Postgrex.prepare(conn_in, "", "COPY #{table_a} TO STDOUT")
        stream_in = Postgrex.stream(conn_in, query, [])

        Postgrex.transaction(conn_bar, fn(conn_out) ->
          result_to_iodata = fn(%Postgrex.Result{rows: rows}) -> rows end
          stream_out = Postgrex.stream(conn_out, "COPY #{table_b} FROM STDIN", [])
          Enum.into(stream_in, stream_out, result_to_iodata)
        end)
        destroy_query(conn_foo, query)
      end)
      
      # close connections
      close(conn_foo)
      close(conn_bar)
      
      {:ok, ""}
    else
      _ -> {:error, "is not possible COPY source in dest"}
    end
  end

  @doc """
  Visit a table, using stream, and call the callback function for each row
  """
  def stream_table(stream_conn, db_name, table_name, callback) do
    case Adjust.Repo.connect(db_name) do
      {:ok, conn} ->
        Postgrex.transaction(conn, fn(conn_in) ->
          {:ok, query} = Postgrex.prepare(conn_in, "", "SELECT a, b, c FROM #{table_name}")
          stream_in = Postgrex.stream(conn_in, query, [], max_rows: 1000)
          Enum.reduce(
            stream_in,
            stream_conn,
            fn(%Postgrex.Result{rows: rows}, web_conn) ->
              callback.(web_conn, rows)
          end)
        end)
      _ ->
        callback.({:error, "error querying table"})
    end
  end

  ### PRIVATE ###

  defp values(_x, 0), do: ""

  defp values(x, n) do
    ["($#{x}, $#{x + 1}, $#{x + 2})", values(x + 3, n - 1)]
    |> Enum.filter(&(String.length(&1) > 0))
    |> Enum.join(",")
  end
end
