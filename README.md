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

## Usage

- to initialize the DB: Adjust.init()
- to fill the DB: Adjust.fill()
- to copy source to dest: Adjust.copy_to_dest()

The webserver is availabe at port 4001:
wget http://127.0.0.1:4001//dbs/foo/tables/source