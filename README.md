# Adjust

## Preparing

Start postgres:
docker run --name my-postgres -e POSTGRES_PASSWORD=qwerty -d -p 5432:5432 postgres:9.5 -N 1000

Connection:
psql -h 127.0.0.1 -U postgres -d postgres --password

Kill and Remover: docker kill my-postgres && docker rm my-postgres

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `adjust` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:adjust, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/adjust](https://hexdocs.pm/adjust).
