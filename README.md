# Karazin CI/CD — Tasks REST API

Task CRUD service built with Dart and Serverpod 4.0.4, backed by PostgreSQL.
The workspace contains the server (`karazin_ci_cd_server`) and generated client
(`karazin_ci_cd_client`). Run commands from the repository root unless noted.

## Local setup and run

Requirements: Dart 3.12.2 or later within 3.x, and Serverpod CLI 4.0.4.
Docker is only needed for the container workflow below.

```sh
dart pub global activate serverpod_cli 4.0.4
dart pub get
serverpod start
```

Ensure the Pub cache `bin` directory is on your PATH. `serverpod start` manages
code generation, migrations, and hot reload; press **Q** to stop it.
The development configuration uses embedded PostgreSQL at
`karazin_ci_cd_server/.serverpod/development/pgdata` (port 8090), so local
startup does not need `docker compose up`. Do not run a separate database on
that same port at the same time.

## REST API and documentation

Base URL: **http://localhost:8082**. These routes are registered on
`pod.webServer` in `karazin_ci_cd_server/lib/server.dart`.

| Method | Path | Behavior / success status |
| --- | --- | --- |
| GET | `/api/tasks` | List tasks by creation time; 200 |
| POST | `/api/tasks` | Create a task; 201 |
| GET | `/api/tasks/{id}` | Read a task; 200 |
| PUT | `/api/tasks/{id}` | Update supplied fields; 200 |
| DELETE | `/api/tasks/{id}` | Delete a task; 204 |

Task fields: `id`, `title`, nullable `description`, `completed`, and `createdAt`.
Creation requires a title whose trimmed length is 1–100 characters; `completed`
defaults to `false`. Missing task IDs return 404. Current PUT handling does not
apply the title validator, and the description validator is only unit-tested,
not called by the routes.

```sh
curl -X POST http://localhost:8082/api/tasks \
  -H 'Content-Type: application/json' \
  -d '{"title":"Learn Serverpod","description":"Implement REST CRUD"}'
curl http://localhost:8082/api/tasks
```

- Swagger UI: [http://localhost:8082/docs](http://localhost:8082/docs)
- OpenAPI JSON: [http://localhost:8082/openapi.json](http://localhost:8082/openapi.json)

Swagger UI loads its assets from a CDN and needs internet access. The OpenAPI
server URL is currently hard-coded to `http://localhost:8082`; update it in
`open_api_route.dart` when deploying to a different address.
Port 8080 is the Serverpod API server; 8081 is Insights; **8082 serves this REST API**.

## Unit tests

Run from the server package, not the workspace root:

```sh
cd karazin_ci_cd_server
dart test
```

The current suite contains eight pure `TaskValidator` unit tests in
`test/integration/modules/tasks/task_validator_test.dart`; despite the directory
name, these tests do not start a server or require a database or Docker.

## Docker build and run

Start Docker Desktop (or Docker Engine). Build from the **repository root**,
so the Dockerfile can access the workspace `pubspec.lock`:

```sh
docker build -f karazin_ci_cd_server/Dockerfile -t karazin-ci-cd .
```

The image defaults to production mode. `config/production.yaml` contains example
hostnames and database credentials settings, so a bare `docker run` is not a
complete deployment. The following local demo supplies a separate PostgreSQL
container and overrides those settings. Stop the local server first to free 8082.
Run these commands in the same terminal; replace the example password.

```sh
export SERVERPOD_DATABASE_PASSWORD='replace-with-a-local-demo-password'
docker network create karazin-ci-cd
docker run -d --name karazin-ci-cd-db --network karazin-ci-cd \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=karazin_ci_cd \
  -e POSTGRES_PASSWORD="$SERVERPOD_DATABASE_PASSWORD" \
  -v karazin-ci-cd-db-data:/var/lib/postgresql/data \
  ghcr.io/serverpod/postgres:16

docker exec karazin-ci-cd-db pg_isready -U postgres -d karazin_ci_cd
```

Wait until `pg_isready` reports **accepting connections** (repeat that command
if necessary), then start the application and apply its bundled migrations:

```sh
docker run --rm --name karazin-ci-cd-app --network karazin-ci-cd \
  -p 127.0.0.1:8082:8082 \
  -e SERVERPOD_DATABASE_HOST=karazin-ci-cd-db \
  -e SERVERPOD_DATABASE_PORT=5432 \
  -e SERVERPOD_DATABASE_NAME=karazin_ci_cd \
  -e SERVERPOD_DATABASE_USER=postgres \
  -e SERVERPOD_DATABASE_PASSWORD \
  -e SERVERPOD_DATABASE_REQUIRE_SSL=false \
  -e SERVERPOD_WEB_SERVER_PUBLIC_HOST=localhost \
  -e SERVERPOD_WEB_SERVER_PUBLIC_PORT=8082 \
  -e SERVERPOD_WEB_SERVER_PUBLIC_SCHEME=http \
  -e SERVERPOD_SESSION_CONSOLE_LOG_ENABLED=true \
  karazin-ci-cd --apply-migrations
```

Open `/docs` or run the curl examples above. `--apply-migrations` applies pending
migrations before serving requests; startup arguments are forwarded by the
Dockerfile. The SSL override is for this local database demo. Real deployments
need their own database, secrets, public hostnames, and TLS configuration.
Insights additionally needs a configured service secret if you intend to use it.

Press Ctrl+C to stop the app, or run `docker stop karazin-ci-cd-app` from another
terminal. Stop the database with `docker stop karazin-ci-cd-db`; restart it later
with `docker start karazin-ci-cd-db` and rerun the app command. The named volume
preserves database data. Create the network and database container only once.

### Assignment №2: Dockerfile requirements

| Requirement | Implementation in `karazin_ci_cd_server/Dockerfile` |
| --- | --- |
| Builds the application | `dart pub get`, then `dart build cli --target bin/main.dart --output build` |
| Produces a runnable image | Multi-stage build copies the compiled bundle, runtime, configuration, web resources, migrations, and protocol metadata into the final image |
| Exposes the web-service port | `EXPOSE 8082` (also 8080 and 8081); `-p 127.0.0.1:8082:8082` publishes the REST port locally |
| Starts the application on container start | `ENTRYPOINT` executes `./bin/server`, with run mode and other settings from environment variables |

The Dockerfile meets all four structural requirements. `EXPOSE` alone does not
publish a port, and a runnable service still requires a reachable, configured
database. The root `.dockerignore` excludes local secrets, build caches, and
embedded database files; provide secrets at runtime. Build instructions follow
the [Serverpod hosting documentation](https://docs.serverpod.dev/deployments/custom-hosting/hosting-elsewhere).

Validation: Dockerfile and commands reviewed against repository configuration;
an actual image build and container startup still need verification with a
running Docker daemon.
