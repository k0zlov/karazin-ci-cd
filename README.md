# Karazin CI/CD — Tasks REST API

Task CRUD service built with Dart and Serverpod 4.0.4, backed by PostgreSQL.
The workspace contains the server (`karazin_ci_cd_server`) and generated client
(`karazin_ci_cd_client`). Run commands from the repository root unless noted.

## Quick start with Docker Compose

Start Docker Desktop (or Docker Engine with Compose). From the repository root,
enter the **server directory** and start the service:

```sh
cd karazin_ci_cd_server
docker compose up --build -d
```

Compose builds the app, starts PostgreSQL, waits for the database to be ready,
and applies pending migrations before serving requests. No local Dart or
Serverpod installation is needed. The first build needs internet access.
Stop any local server using port 8082 before starting.

Open [Swagger UI](http://localhost:8082/docs) to try the API, or use
[the task list](http://localhost:8082/api/tasks). Startup may take a moment. Run these commands from the server directory:

```sh
docker compose logs -f app   # Follow startup logs; Ctrl+C stops following logs
docker compose ps            # Show container status
docker compose down          # Stop and remove containers; keep database data
```

Run `docker compose up --build -d` again to restart or rebuild after code changes.
PostgreSQL data persists in a named volume. `docker compose down -v` also deletes
that volume and **all tasks in this Compose database**.

`karazin_ci_cd_server/docker-compose.yaml` runs both the app and PostgreSQL.
Its build context is the repository root (`..`), so the Dockerfile can read the
workspace lockfile. Compose uses its own database; it does not import data from
local development or the earlier manual Docker setup.

This is a local demo: port 8082 is published only on localhost, PostgreSQL stays
inside the Compose network, and a default demo password is supplied automatically.
Optionally set `SERVERPOD_DATABASE_PASSWORD` in your shell before the first run;
keep using the same value for that volume. Changing it later does not change the
password already stored in PostgreSQL. Production deployment requires its own
secrets, public hostnames, and TLS configuration.

To build only the image without starting services, from the server directory:

```sh
docker compose build
# Equivalent standalone build:
docker build -f Dockerfile -t karazin-ci-cd ..
```

## Local setup and run (without containers)

Requirements: Dart 3.12.2 or later within 3.x, and Serverpod CLI 4.0.4.
Docker is only needed for the Compose workflow above. Run the following commands
from the **repository root**.

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

## Assignment №2: Dockerfile requirements

| Requirement | Implementation in `karazin_ci_cd_server/Dockerfile` |
| --- | --- |
| Builds the application | `dart pub get`, then `dart build cli --target bin/main.dart --output build` |
| Produces a runnable image | Multi-stage build copies the compiled bundle, runtime, configuration, web resources, migrations, and protocol metadata into the final image |
| Exposes the web-service port | `EXPOSE 8082` (also 8080 and 8081); Compose publishes `127.0.0.1:8082:8082` for local REST access |
| Starts the application on container start | `ENTRYPOINT` executes `./bin/server`, with run mode and other settings from environment variables |

The Dockerfile meets all four structural requirements. `EXPOSE` alone does not
publish a port, and a runnable service still requires a reachable, configured
database. The root `.dockerignore` excludes local secrets, build caches, and
embedded database files; provide secrets at runtime. Build instructions follow
the [Serverpod hosting documentation](https://docs.serverpod.dev/deployments/custom-hosting/hosting-elsewhere).

Validation: `docker compose config --quiet` and `docker compose build` passed.
Container startup and HTTP requests have not yet been tested with this Compose setup.

## Azure DevOps CI/CD — assignments №4 and №5

The root `azure-pipelines.yml` builds the Dart application, runs unit tests, then
builds, tags, and pushes the application image to Docker Hub as `latest` after a
push to `main`. Publishing requires a successful build and test run.

Follow the [Azure DevOps setup guide](docs/AZURE_DEVOPS.md) to create the Docker
Hub repository, Azure DevOps project, `docker-hub` service connection, and GitHub
pipeline. Set the pipeline variable `dockerHubRepository` to your
`<namespace>/karazin-ci-cd`. Store the Docker Hub token in the service connection.

## GitHub Actions CI — build, test, and Docker publication

The `CI` workflow runs on pushes to `main`, `feature/*`, and `bugfix/*`.
Changes limited to `docs/**` and the root `README.md` are ignored. A push that
also changes application code still runs CI. Analysis and formatting workflows
use the same push filters and retain checks for pull requests targeting `main`.

- `build-n-test` builds the server with Dart 3.12.2 and runs unit tests.
- `docker-pack-n-push` calls a separate reusable workflow after tests pass.
- On `main`, it publishes `<namespace>/karazin-ci-cd:latest` to Docker Hub.
- On feature/bugfix branches, it saves the image as a downloadable workflow artifact.

Set the Actions repository variable `DOCKERHUB_REPOSITORY` to
`<namespace>/karazin-ci-cd`. Add `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` to the repository's **Settings →
Secrets and variables → Actions → New repository secret** before the first main
run. See the [GitHub Actions setup and verification guide](docs/GITHUB_ACTIONS.md).
The Azure pipeline from the previous lab remains enabled independently; both
pipelines can publish `latest` on pushes to `main`. These GitHub path filters do
not affect Azure's trigger.

