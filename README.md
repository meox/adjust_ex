# Adjust

## Preparing

Start postgres:
docker run --name my-postgres -e POSTGRES_PASSWORD=qwerty -d -p 5432:5432 postgres:9.5 -N 1000

Connection:
psql -h 127.0.0.1 -U postgres -d postgres --password

Kill and Remover: docker kill my-postgres && docker rm my-postgres

## Setup

- mix deps.get
- mix compile
