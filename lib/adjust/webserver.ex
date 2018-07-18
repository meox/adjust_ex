defmodule Adjust.WebServer do
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Adjust API")
  end

  get "/dbs/foo/tables/source" do
    send_resp(conn, 200, "world")
  end

end