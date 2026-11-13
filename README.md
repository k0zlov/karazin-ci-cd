# Karazin CI/CD — Tasks REST API

Task CRUD service built with Dart and Serverpod 4.0.4, backed by PostgreSQL.
The workspace contains the server (`karazin_ci_cd_server`) and generated client
(`karazin_ci_cd_client`). Run commands from the repository root unless noted.

## Quick start with Docker Compose

Start Docker Desktop (or Docker Engine with Compose), then run from the repository root:

```sh
docker compose up --build -d
```

Compose builds the app, starts PostgreSQL, waits for the database to be ready,
and applies pending migrations before serving requests. No local Dart or
Serverpod installation is needed. The first build needs internet access.
Stop any local server using port 8082 before starting.

Open [Flutter Web](http://localhost:8083) to manage tasks or
[Swagger UI](http://localhost:8082/docs) to try the API. Startup may take a moment.
Run these commands from the repository root:

```sh
docker compose logs -f app   # Follow startup logs; Ctrl+C stops following logs
docker compose ps            # Show container status
docker compose down          # Stop and remove containers; keep database data
```

Run `docker compose up --build -d` again to restart or rebuild after code changes.
PostgreSQL data persists in a named volume. `docker compose down -v` also deletes
that volume and **all tasks in this Compose database**.

The root `docker-compose.yaml` runs Flutter Web, Serverpod, and PostgreSQL.
The Serverpod build uses the repository root as its context so it can read the
workspace lockfile. Compose uses its own database; it does not import data from
local development or the earlier manual Docker setup.

Flutter Web reads `API_BASE_URL` from Compose. The default points to Serverpod's
public web server at `http://localhost:8082`. To point the browser at a different
API, recreate the web container with a URL accessible from that browser:

```sh
API_BASE_URL=https://api.example.com docker compose up -d --no-build web
```

This is a local demo: ports 8082 and 8083 are published only on localhost, PostgreSQL stays
inside the Compose network, and a default demo password is supplied automatically.
Optionally set `SERVERPOD_DATABASE_PASSWORD` in your shell before the first run;
keep using the same value for that volume. Changing it later does not change the
password already stored in PostgreSQL. Production deployment requires its own
secrets, public hostnames, and TLS configuration.

To build the images without starting services, run from the repository root:

```sh
docker compose build
# Standalone Serverpod build:
docker build -f karazin_ci_cd_server/Dockerfile -t karazin-ci-cd .
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

The **Backend (Serverpod) → Docker Hub** workflow
(`backend-docker-hub.yml`) runs on pushes to `main`,
`feature/*`, and `bugfix/*`.
Changes limited to `docs/**` and the root `README.md` are ignored. A push that
also changes application code still runs CI. Analysis and formatting workflows
use the same push filters and retain checks for pull requests targeting `main`.

- `build-n-test` builds the server with Dart 3.12.2 and runs unit tests.
- After backend tests pass, `docker-hub-publish-and-archive.yml` builds the image,
  publishes it on `main`, and saves an archive in GitHub Actions.
- **Frontend (Flutter Web) → Docker Hub** (`frontend-docker-hub.yml`) calls
  the same reusable workflow with `karazin_ci_cd_flutter/` as the build context.
- On `main`, Docker Hub receives `latest` and `sha-<commit-sha>` tags for
  `<namespace>/karazin-ci-cd` and `<namespace>/karazin-ci-cd-flutter`.
- GitHub Actions Artifacts retains `karazin-ci-cd-docker-image.tar.gz` or
  `karazin-ci-cd-flutter-docker-image.tar.gz` for seven days after each successful build.

Set the Actions repository variable `DOCKERHUB_REPOSITORY` to
`<namespace>/karazin-ci-cd`. Add `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` to the repository's **Settings →
Secrets and variables → Actions → New repository secret** before the first main
run. The token needs write access to both Docker Hub repositories. See the
[GitHub Actions setup and verification guide](docs/GITHUB_ACTIONS.md).
The Azure pipeline from the previous lab can also publish the backend's
`latest` tag on pushes to `main`.

## Lab 4, assignment 3 — Kubernetes and Helm

The application chart is in `k8s/`. `Chart.yaml` sets chart version `0.1.0`
and application version `1.0.0`. The Docker image tags are set separately in
`values.yaml`.

### What the chart installs

| Component | Kubernetes resources |
| --- | --- |
| Flutter Web | Deployment and Service, with the public API origin injected at startup |
| Serverpod REST API | Deployment and Service on port 8082 by default |
| PostgreSQL | StatefulSet, headless Service, and a PVC allocated by the cluster's default StorageClass |
| Database migrations | A separate Job that waits for an authenticated database connection and applies migrations in maintenance mode |
| HTTP routing | Ingress sends `/api` to Serverpod and `/` to Flutter, preserving the request path |

The API pods wait for the migration Job for their Helm revision to complete.
Each upgrade gets a new Job. Keep a completed Job while that revision is deployed
so replacement API pods can start. Use backward-compatible database migrations
during rolling upgrades. A Helm rollback does not roll back the database schema.

Flutter reads the browser-visible origin from `/api-base-url.txt`. The default
Ingress origin is `http://localhost:18080`, so the browser calls both the app and
API from the same origin. The Serverpod REST routes already handle CORS for
clients using a separate origin.

### Validate and package

Use Helm 3, kubectl, kind, and a running Docker Desktop. From the repository
root, set `DOCKERHUB_REPOSITORY` to the same full backend image repository as
the GitHub Actions variable, replacing the namespace placeholder below.

```sh
DOCKERHUB_REPOSITORY='<namespace>/karazin-ci-cd'

helm lint ./k8s --strict --set-string "images.repository=$DOCKERHUB_REPOSITORY"
helm template karazin ./k8s --namespace karazin-lab4 \
  --set-string "images.repository=$DOCKERHUB_REPOSITORY"
helm package ./k8s --destination dist
helm show chart dist/karazin-ci-cd-0.1.0.tgz
```

The chart uses this repository for the backend and appends `-flutter` and
`-migrations` for the other two images. The default tag is `latest`. Set
`backend.image.tag`, `frontend.image.tag`, and `migrations.image.tag` separately
to pin published tags. Each component also accepts a repository override and
an image digest. Use `images.pullSecrets` for private repositories.

### Install on a one-node kind cluster

Run this in a dedicated shell. The kubeconfig file isolates these commands from
your other Kubernetes contexts. Docker Compose and its database can run separately.

```sh
export KUBECONFIG="$(mktemp -d)/karazin-lab4.kubeconfig"
kind create cluster --name karazin-lab4 --image kindest/node:v1.34.0 \
  --kubeconfig "$KUBECONFIG" --wait 2m
kubectl get nodes
kubectl get storageclass

helm repo add traefik https://traefik.github.io/charts
helm repo update traefik
helm upgrade --install traefik traefik/traefik --version 42.4.0 \
  --namespace traefik --create-namespace \
  --set service.spec.type=ClusterIP \
  --set providers.kubernetesCRD.enabled=false \
  --set providers.kubernetesIngress.strictPrefixMatching=true \
  --set ingressClass.isDefaultClass=false --skip-crds --wait --timeout 4m

kubectl create namespace karazin-lab4
openssl rand -hex 32 | tr -d '\n' | kubectl -n karazin-lab4 create secret generic karazin-db \
  --from-file=password=/dev/stdin
```

The Secret is shared by PostgreSQL, the migrator, and the API. Keep the Secret
while reusing the PVC. Replacing the Secret alone does not change PostgreSQL's
existing password. Override its name or key with `postgresql.existingSecret` and
`postgresql.passwordKey`. Set `postgresql.storage.className` if the cluster
uses a different StorageClass.

For an amd64 node or multi-architecture images, install the package directly.

```sh
helm install karazin dist/karazin-ci-cd-0.1.0.tgz --namespace karazin-lab4 \
  --set-string "images.repository=$DOCKERHUB_REPOSITORY" \
  --wait --wait-for-jobs --timeout 6m
```

For Apple Silicon with the amd64-only images published by this project's CI,
enable x86-64 emulation in Docker Desktop. Use the amd64 manifest digest for
each image so the ARM64 node can fetch the correct image directly from Docker Hub.
For each repository, copy the digest shown next to the `linux/amd64` platform.

```sh
docker buildx imagetools inspect "$DOCKERHUB_REPOSITORY:latest"
docker buildx imagetools inspect "${DOCKERHUB_REPOSITORY}-flutter:latest"
docker buildx imagetools inspect "${DOCKERHUB_REPOSITORY}-migrations:latest"

helm install karazin dist/karazin-ci-cd-0.1.0.tgz --namespace karazin-lab4 \
  --set-string "images.repository=$DOCKERHUB_REPOSITORY" \
  --set-string 'backend.image.digest=sha256:<backend-amd64-digest>' \
  --set-string 'frontend.image.digest=sha256:<frontend-amd64-digest>' \
  --set-string 'migrations.image.digest=sha256:<migrations-amd64-digest>' \
  --wait --wait-for-jobs --timeout 6m
```

### Verify the release and browser CRUD

```sh
helm status karazin -n karazin-lab4
kubectl -n karazin-lab4 get pods,job,pvc,ingress
kubectl -n karazin-lab4 logs job/karazin-migrate-1 -c migrations
kubectl -n traefik port-forward --address 127.0.0.1 svc/traefik 18080:80
```

Keep the port-forward running. Open [Flutter Web](http://localhost:18080).
Create a task, refresh to verify it was saved, edit it and mark it complete,
then delete it. [The REST endpoint](http://localhost:18080/api/tasks) lists the
current tasks through the same Ingress. If using another public address, set
`ingress.host`, `ingress.publicPort`, and `ingress.publicScheme` together.
Set `ingress.tlsSecretName` and configure the controller's HTTPS entry point
when serving HTTPS. If disabling the Ingress, set `frontend.apiBaseUrl` to the
API origin reachable from the browser.

Use `helm upgrade` with the same namespace and image settings to update a release.
Use `helm uninstall karazin -n karazin-lab4` to remove the application and
keep the PostgreSQL PVC. `kind delete cluster --name karazin-lab4` removes the
entire lab cluster, including its local PostgreSQL volume.

### GitHub Actions artifact

The [Helm Chart workflow](.github/workflows/helm-chart.yml) runs strict linting,
renders the manifests, packages the chart, and uploads
`karazin-ci-cd-0.1.0.tgz` as the `karazin-ci-cd-helm-chart` run artifact. Open
the workflow run in GitHub Actions and download the artifact ZIP. Extract it
and install the enclosed `.tgz` using the same image settings as above.
