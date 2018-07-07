defmodule Adjust.Repo do
  def connect(database \\ "postgres") do
    Postgrex.start_link(
      hostname: "localhost",
      username: "postgres",
      password: "qwerty",
      database: database
    )
  end

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

  def get_source_query(conn) do
    Postgrex.prepare(conn, "INSERT INTO source(a, b, c) VALUE($1, $2, $3)")
  end

  def insert_into_source(conn, query, params) do
    Postgrex.execute(conn, query, params)
  end
end
