# Azure DevOps и Docker Hub — задания №4 и №5

Репозиторий исходного кода: [k0zlov/karazin-ci-cd](https://github.com/k0zlov/karazin-ci-cd).
Pipeline описан в корневом [`azure-pipelines.yml`](../azure-pipelines.yml).
Compose остаётся в `karazin_ci_cd_server/docker-compose.yaml` и используется для
локального запуска. В CI база данных не нужна: текущие восемь unit-тестов
проверяют `TaskValidator`, не запуская сервер.

## 1. Создать репозиторий Docker Hub

В [Docker Hub](https://hub.docker.com/) открой **Repositories → Create repository**:

- Namespace: твой пользователь или организация Docker Hub.
- Repository name: `karazin-ci-cd`.
- Visibility: выбери доступность репозитория по требованиям курса.

Полное имя образа будет `<namespace>/karazin-ci-cd:latest`.
В настройках аккаунта Docker создай Personal Access Token с правами чтения
и записи репозиториев (**Repo Read & Write**). Он понадобится только в форме
Service Connection — не добавляй его в Git, YAML или README.

## 2. Создать проект Azure DevOps

Открой свою организацию на `https://dev.azure.com/<organization>` и нажми
**New project**. Например, назови проект `karazin-ci-cd`, выбери **Private**
и создай его. Если организации ещё нет, сначала создай организацию Azure DevOps.
Для новой организации Microsoft сейчас требует активную подписку Azure — см.
[условия создания организации](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/create-organization?view=azure-devops).
Копировать код в Azure Repos не нужно: источником останется GitHub.

## 3. Подключить Docker Hub

В проекте Azure DevOps:

1. **Project settings → Service connections → New service connection**.
2. Тип: **Docker Registry**; Registry type: **Docker Hub**.
3. Введи Docker ID и Personal Access Token в поле пароля/токена.
4. Имя соединения: **`docker-hub`** — именно это имя указано в YAML.
5. Проверь и сохрани соединение. Разреши его использование этому pipeline
   при первом запуске или через Pipeline permissions соединения.

## 4. Создать pipeline с источником GitHub

Сначала закоммить и отправь `azure-pipelines.yml`, этот документ и изменения
README в ветку `main` репозитория GitHub.

В Azure DevOps:

1. **Pipelines → New pipeline → GitHub**.
2. Авторизуй GitHub / Azure Pipelines GitHub App и предоставь доступ к
   `k0zlov/karazin-ci-cd`.
3. Выбери этот репозиторий, затем **Existing Azure Pipelines YAML file**.
4. Branch: `main`; Path: `/azure-pipelines.yml`.
5. В **Variables** добавь `dockerHubRepository` со значением
   `<твой-namespace>/karazin-ci-cd`, без `https://`, без `docker.io/` и без тега.
   Эта переменная не является секретом.
6. Сохрани pipeline и запусти его. Если появляется запрос на доступ к
   `docker-hub`, разреши использование соединения этому pipeline.

После привязки pipeline каждый push в `main` запускает CI автоматически.
`batch: true` объединяет новые push, пришедшие во время выполняющегося CI,
в следующий запуск. Автозапуск для pull request выключен (`pr: none`).
Ручной запуск из другой ветки выполнит сборку и тесты, но пропустит публикацию.
Не включай в интерфейсе Azure override YAML CI triggers, отключающий этот trigger.

## 5. Что выполняет pipeline

| Требование | Шаг |
| --- | --- |
| Сборка проекта | В контейнере `dart:3.12.2`: `dart pub get`, затем `dart build cli` |
| Unit-тесты | `dart test --reporter expanded` из серверного пакета |
| Сборка Docker-образа | `Docker@2`, существующий серверный Dockerfile; build context — корень workspace |
| Назначение тега | `docker tag` присваивает целевому образу тег `latest` |
| Публикация | `Docker@2 push` в Docker Hub через соединение `docker-hub` |

При ошибке сборки или тестов стадия публикации не запускается. Сборка Docker,
назначение тега и push выполняются в одном job, поэтому образ доступен всем
трём шагам. Временный локальный тег использует ID запуска; в Docker Hub
публикуется только `latest`, без расчёта следующей версии.

В Docker Hub загружается образ приложения. PostgreSQL и содержимое его тома
не входят в этот образ. Для запуска опубликованного образа также нужна БД.

## Проверка результата

- После push в `main` в Azure Pipelines появляется новый автоматический запуск.
- Стадия BuildAndTest успешно собирает приложение и выполняет восемь тестов.
- Стадия PublishImage успешно выполняет build, tag и push.
- В Docker Hub у `<namespace>/karazin-ci-cd` появляется/обновляется тег `latest`.

Если Azure сообщает **No hosted parallelism has been purchased or granted**,
нужно настроить доступ к Microsoft-hosted agents в организации либо использовать
собственный Linux agent с Docker и подходящим пулом. См. актуальные
[условия parallel jobs](https://learn.microsoft.com/en-us/azure/devops/pipelines/licensing/concurrent-jobs?view=azure-devops).
Не требуется запускать Docker Compose внутри pipeline.

## Источники

- [Microsoft: публикация Docker-образов](https://learn.microsoft.com/en-us/azure/devops/pipelines/ecosystems/containers/push-image?view=azure-devops)
- [Microsoft: Docker@2](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/docker-v2?view=azure-pipelines)
- [Docker: Personal Access Tokens](https://docs.docker.com/security/access-tokens/personal-access-tokens/)

Проверено локально: YAML и синтаксис shell-команд; сборка приложения и все восемь
unit-тестов в Linux-контейнере `dart:3.12.2`. Сам запуск в Azure DevOps и push в
Docker Hub ещё не проверены: аккаунты и Service Connection пока не созданы.
