# GitHub Actions: build, test, and Docker publication

## Repository settings

Open **Settings → Secrets and variables → Actions** in the GitHub repository.
Add the following repository secrets under **Secrets**:

| Secret | Value |
| --- | --- |
| `DOCKERHUB_USERNAME` | Docker ID with write access to the target repository |
| `DOCKERHUB_TOKEN` | Docker Hub Personal Access Token with Read & Write permissions |

Under **Variables**, add `DOCKERHUB_REPOSITORY` with the full Docker Hub image
repository name: `<namespace>/karazin-ci-cd`. Do not include a URL scheme or tag.
Use the actual namespace only in the repository settings, never in documentation
or committed configuration.

The Azure DevOps `docker-hub` service connection does not share its credentials
with GitHub Actions. Feature and bugfix builds need the repository variable but
not the secrets. Enter tokens only in GitHub Secrets.

## Workflow structure and assignment requirements

| Requirement | Implementation |
| --- | --- |
| `build-n-test` job | `.github/workflows/ci.yml`: restore dependencies, `dart build cli`, then `dart test` |
| Branch triggers | Pushes to `main`, `feature/*`, and `bugfix/*` |
| Documentation exclusions | `paths-ignore` excludes `docs/**` and the root `README.md` |
| `docker-pack-n-push` job | Calls the reusable workflow after `build-n-test` succeeds |
| Reusable workflow | `.github/workflows/docker-pack-n-push.yml`, triggered by `workflow_call` |
| Inputs | `repository`, `tag`, `context`, and `dockerfile` |
| Credentials | GitHub Secrets, explicitly passed to the reusable workflow only for main |
| Publication | Login and push run only for push events on `refs/heads/main` |
| Other branches | `docker save` produces `image.tar.gz`, uploaded as an artifact retained for seven days |

The `repository` input receives `vars.DOCKERHUB_REPOSITORY`. The default tag is
`latest`, the build context is `.` (the workspace root), and the Dockerfile is
`karazin_ci_cd_server/Dockerfile`. The root context includes `pubspec.lock`.

The previous `tests.yml` is replaced by `ci.yml` to avoid duplicate unit tests.
Analyze and Format remain enabled with matching push/path filters and checks on
pull requests targeting main. If branch protection requires the old `Tests / test`
status, select the new `build-n-test` check after the first workflow run.

Path filters skip a workflow only when every changed file matches an exclusion.
A push containing application changes and README changes still runs CI.
`feature/*` matches `feature/tasks`, but not `feature/team/tasks`. The image CI
has no additional pull-request trigger to avoid duplicating branch builds.

## Verification

After configuring the variable and secrets, commit and push the workflow changes.

1. Push a code or workflow change to `main`. Both jobs should pass, and Docker Hub
   should receive the `latest` tag.
2. Push a code change to `feature/ci-check` or `bugfix/ci-check`. The run should
   contain an artifact named `docker-image-<run-id>-<attempt>`. Login and push
   should be skipped.
3. Push only changes to `docs/**` and/or the root `README.md`. CI, Analyze, and
   Format should not run.

Download and extract the artifact ZIP from the Actions run. Load the image:

```sh
docker load --input image.tar.gz
docker image inspect '<namespace>/karazin-ci-cd:latest'
```

Replace the namespace placeholder locally with the configured repository value.
The artifact contains a complete Docker image. Running the application still
requires PostgreSQL and database connection settings.

The Azure pipeline from the previous assignment remains enabled independently.
It can also publish `latest` on main and does not use the GitHub path filters.
If only GitHub CI is required, disable automatic runs in Azure DevOps while
preserving the previous assignment's pipeline file.

## References

- [GitHub: reusable workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)
- [GitHub: workflow syntax and path filters](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- [Docker: login action and access tokens](https://github.com/docker/login-action)
