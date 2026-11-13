# GitHub Actions: build, test, and Docker publication

## Repository settings

Create or verify the `karazin-ci-cd` and `karazin-ci-cd-flutter` repositories
in the same Docker Hub namespace. Open **Settings → Secrets and variables →
Actions** in the GitHub repository and add these secrets:

| Secret | Value |
| --- | --- |
| `DOCKERHUB_USERNAME` | Docker ID with write access to both Docker Hub repositories |
| `DOCKERHUB_TOKEN` | Docker Hub token with write access to both Docker Hub repositories |

Under **Variables**, add `DOCKERHUB_REPOSITORY` with the full Docker Hub image
repository name: `<namespace>/karazin-ci-cd`. Do not include a URL scheme or tag.
Use the actual namespace only in the repository settings, never in documentation
or committed configuration.

The Flutter workflow appends `-flutter` to this variable. Feature and bugfix
builds use the variable to tag their image archives. Publication uses the Docker
Hub credentials on main.

## Workflow structure and assignment requirements

| Requirement | Implementation |
| --- | --- |
| `build-n-test` job | `.github/workflows/backend-docker-hub.yml`: restore dependencies, `dart build cli`, then `dart test` |
| Branch triggers | Pushes to `main`, `feature/*`, and `bugfix/*` |
| Documentation exclusions | `paths-ignore` excludes `docs/**` and the root `README.md` |
| Backend image | **Backend (Serverpod) → Docker Hub** calls the reusable workflow after `build-n-test` succeeds |
| Frontend image | `.github/workflows/frontend-docker-hub.yml` calls the reusable workflow when Flutter source or its workflow files change |
| Reusable workflow | `.github/workflows/docker-hub-publish-and-archive.yml`, triggered by `workflow_call` |
| Inputs | `repository`, `tag`, `context`, and `dockerfile` |
| Credentials | GitHub Secrets, explicitly passed to the reusable workflow only for main |
| Publication | Pushes to `main` publish `latest` and `sha-<commit-sha>` to Docker Hub |
| Run artifacts | GitHub Actions Artifacts retains `karazin-ci-cd-docker-image.tar.gz` or `karazin-ci-cd-flutter-docker-image.tar.gz` for seven days |

The backend uses the repository root as its context so
`karazin_ci_cd_server/Dockerfile` can read the workspace lockfile. The Flutter
context is `karazin_ci_cd_flutter/`, which contains its Dockerfile and lockfile.
Set `API_BASE_URL` to the browser-accessible backend URL when starting the
Flutter container. Compose defaults it to `http://localhost:8082`.

The backend workflow runs unit tests in the `build-n-test` job.
Analyze and Format remain enabled with matching push/path filters and checks on
pull requests targeting main. If branch protection requires the old `Tests / test`
status, select the new `build-n-test` check after the first workflow run.

Path filters skip a workflow only when every changed file matches an exclusion.
A push containing application changes and README changes still runs CI.
`feature/*` matches `feature/tasks`, but not `feature/team/tasks`. The image CI
has no additional pull-request trigger to avoid duplicating branch builds.

## Verification

After configuring the variable and secrets, commit and push the workflow changes.

1. Push both workflow changes and the Flutter source to `main`. Check that
   both images appear in Docker Hub with `latest` and `sha-<commit-sha>`.
2. Push a Flutter change to `feature/ci-check` or `bugfix/ci-check`. The run should
   contain an artifact named `karazin-ci-cd-flutter-docker-image-<run-id>-<attempt>`. Login and push
   should be skipped.
3. Push only changes to `docs/**` and/or the root `README.md`. The image
   workflows, Analyze, and Format should skip the push.

Download and extract the artifact ZIP from the Actions run. Load the image:

```sh
docker load --input karazin-ci-cd-flutter-docker-image.tar.gz
docker image inspect '<namespace>/karazin-ci-cd-flutter:latest'
```

Replace the namespace placeholder with your Docker Hub namespace. Docker Hub
stores images for `docker pull` and deployment. The Actions archive is a
downloadable copy attached to an individual run.

The Azure pipeline from the previous assignment remains enabled independently.
It can also publish `latest` on main and does not use the GitHub path filters.
If only GitHub CI is required, disable automatic runs in Azure DevOps while
preserving the previous assignment's pipeline file.

## References

- [GitHub: reusable workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)
- [GitHub: workflow syntax and path filters](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- [Docker: login action and access tokens](https://github.com/docker/login-action)
