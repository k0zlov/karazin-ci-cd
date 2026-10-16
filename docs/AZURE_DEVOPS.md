# Azure DevOps and Docker Hub: assignments 4 and 5

The root [`azure-pipelines.yml`](../azure-pipelines.yml) defines the pipeline.
Source code remains in the project's GitHub repository. Local startup uses
`karazin_ci_cd_server/docker-compose.yaml`. The eight current unit tests exercise
`TaskValidator` without starting a server or database.

## 1. Create a Docker Hub repository

In [Docker Hub](https://hub.docker.com/), select **Repositories → Create repository**:

- Namespace: your Docker Hub user or organization.
- Repository name: `karazin-ci-cd`.
- Visibility: select the visibility required for the assignment.

The full image name is `<namespace>/karazin-ci-cd:latest`. In Docker account
settings, create a Personal Access Token with **Repo Read & Write** permissions.
Enter this token only in the service connection form, never in Git or documentation.

## 2. Create an Azure DevOps project

Open `https://dev.azure.com/<organization>` and select **New project**. Use a name
such as `karazin-ci-cd` and select **Private**. Create an organization first if
needed. Microsoft requires an active Azure subscription for new organizations;
see the [organization prerequisites](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/create-organization?view=azure-devops).
The source repository stays on GitHub; copying it to Azure Repos is unnecessary.

## 3. Connect Docker Hub

In the Azure DevOps project:

1. Open **Project settings → Service connections → New service connection**.
2. Choose **Docker Registry**, then **Docker Hub**.
3. Enter the Docker ID and Personal Access Token in the credential fields.
4. Name the connection **`docker-hub`**, matching the pipeline configuration.
5. Verify and save. Authorize this pipeline to use the connection through its
   Pipeline permissions or the authorization prompt on the first run.

## 4. Create the GitHub-backed pipeline

Commit and push the pipeline file and documentation to the GitHub `main` branch.

1. Open **Pipelines → New pipeline → GitHub**.
2. Authorize the Azure Pipelines GitHub App for the project's repository.
3. Select the repository and **Existing Azure Pipelines YAML file**.
4. Select branch `main` and path `/azure-pipelines.yml`.
5. Add the pipeline variable `dockerHubRepository` with the value
   `<namespace>/karazin-ci-cd`, without `https://`, `docker.io/`, or a tag.
6. Save and run. Authorize access to `docker-hub` if prompted.

Keep account identifiers in service settings and variables rather than committed
files. After the pipeline is connected, pushes to main trigger CI automatically.
`batch: true` groups pushes arriving during an active run into the next run.
Pull-request triggers are disabled with `pr: none`. Manual runs on other branches
build and test the application but skip publication. Do not override the YAML
trigger with a conflicting setting in the Azure DevOps interface.

## 5. Pipeline steps

| Requirement | Implementation |
| --- | --- |
| Build the project | Run `dart pub get` and `dart build cli` in `dart:3.12.2` |
| Run unit tests | Run `dart test --reporter expanded` in the server package |
| Build the Docker image | Use `Docker@2` with the server Dockerfile and workspace-root build context |
| Assign a tag | Use `docker tag` to assign `latest` |
| Publish the image | Use `Docker@2 push` through the `docker-hub` service connection |

Publication requires successful compilation and tests. Docker build, tagging,
and push run in one job so they share the local image. A temporary local tag uses
the build ID; Docker Hub receives only `latest`.

The image contains the application, not PostgreSQL or its data. Running the
published image requires a database and connection settings.

## Verify the result

- A push to main creates an automatic Azure Pipelines run.
- BuildAndTest successfully compiles the application and runs eight tests.
- PublishImage successfully builds, tags, and pushes the image.
- Docker Hub shows an updated `latest` tag for the configured repository.

If Azure reports **No hosted parallelism has been purchased or granted**, check
Microsoft-hosted job availability for the organization, or configure a Linux
self-hosted agent with Docker. See the current
[parallel jobs documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/licensing/concurrent-jobs?view=azure-devops).
Docker Compose is not needed inside this pipeline.

## References

- [Microsoft: publish Docker images](https://learn.microsoft.com/en-us/azure/devops/pipelines/ecosystems/containers/push-image?view=azure-devops)
- [Microsoft: Docker@2](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/docker-v2?view=azure-pipelines)
- [Docker: Personal Access Tokens](https://docs.docker.com/security/access-tokens/personal-access-tokens/)
