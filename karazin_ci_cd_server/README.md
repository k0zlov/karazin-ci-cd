# karazin_ci_cd_server

Tasks REST API built with Serverpod. See the [project README](../README.md) for
endpoints, tests, and configuration details.

## Run with Docker Compose

From this server directory:

```sh
docker compose up --build -d
```

Open [Swagger UI](http://localhost:8082/docs). Compose starts PostgreSQL and the
app, applies pending migrations, and preserves database data in a named volume.

```sh
docker compose logs -f app
docker compose down
```

## Run locally with Serverpod

From this server directory, return to the project root and start the server:

```sh
cd ..
serverpod start
```

Press **Q** to stop the local server.
