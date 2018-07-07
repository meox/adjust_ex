defmodule Adjust do
  require Logger

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

  def fill_source(conn) do
    with {:ok, conn} <- Adjust.Repo.connect("foo"),
         {:ok, query} <- Adjust.Repo.get_source_query(conn) do
      1..1_000_000
      |> Enum.map(fn x ->
        Adjust.Repo.insert_into_source(conn, query, [e, rem(e, 3), rem(e, 5)])
      end)

      ->(
        _,
        Logger.error("fill_source: is not possible to populate source")
      )
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
end
