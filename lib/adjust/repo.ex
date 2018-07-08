defmodule Adjust.Repo do
  def connect(database \\ "postgres") do
    #todo: take it from conf
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

  defp values(_x, 0), do: ""

  defp values(x, n) do
    ["($#{x}, $#{x + 1}, $#{x + 2})", values(x + 3, n - 1)]
    |> Enum.filter(&(String.length(&1) > 0))
    |> Enum.join(",")
  end
end
