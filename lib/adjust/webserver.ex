defmodule Adjust.WebServer do
  use Plug.Router

  alias Adjust.Repo

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Adjust API")
  end

  get "/dbs/:db_name/tables/:table_name" do
    send_table(conn, db_name, table_name)
  end
  
  match _ do
    send_resp(conn, 404, "oops")
  end

  ### PRIVATE ###

  defp send_table(conn, db_name, table_name) do
    conn = send_chunked(conn, 200)
    
    # send header
    { :ok, conn } = chunk(conn, "a,b,c\n")

    # send the table
    {:ok, conn} = Repo.stream_table(conn, db_name, table_name, fn web_conn, rows ->
      stream_rows(web_conn, rows)
    end)
    conn
  end

  defp stream_rows(conn, []), do: conn
  defp stream_rows(conn, [[a, b, c] | tail]) do
    {:ok, conn} = chunk(conn, "#{a},#{b},#{c}\n")
    stream_rows(conn, tail)
  end
end