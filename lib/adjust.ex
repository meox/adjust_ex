defmodule Adjust do
  require Logger

  @doc """
   Initialize the DBs
  """
  def init() do
    with {:ok, conn} <- Adjust.Repo.connect(),
         {:ok, _result} <- Adjust.Repo.create_db(conn, "foo"),
         {:ok, _result} <- Adjust.Repo.create_db(conn, "bar") do
      create_tables()
    else
      _ -> Logger.error("is not possibile to initialize DB")
    end
  end

  @doc """
  create two tables:
   - "source" into :foo DB
   - "dest" into :bar DB
  """
  defp create_tables() do
    with {:ok, coon_foo} <- Adjust.Repo.connect("foo"),
         {:ok, coon_bar} <- Adjust.Repo.connect("bar"),
         :ok <- Adjust.Repo.create_table(coon_foo, "source"),
         :ok <- Adjust.Repo.create_table(coon_bar, "dest") do
      Logger.info("table created")
    else
      _ -> Logger.error("is not possibile to create table")
    end
  end
end
