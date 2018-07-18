defmodule Adjust.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Adjust.Worker.start_link(arg)
      # {Adjust.Worker, arg},
      Plug.Adapters.Cowboy2.child_spec(scheme: :http, plug: Adjust.WebServer, options: [port: 4001])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Adjust.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
