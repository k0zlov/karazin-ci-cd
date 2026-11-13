FROM --platform=$BUILDPLATFORM debian:bookworm-slim AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils zip \
    && rm -rf /var/lib/apt/lists/*

ENV CI=true
ENV PATH="/opt/flutter/bin:${PATH}"

RUN git clone --depth 1 --branch 3.47.4 https://github.com/flutter/flutter.git /opt/flutter \
    && flutter precache --web

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get --enforce-lockfile

COPY lib/ lib/
COPY web/ web/

RUN flutter build web --release --no-pub --no-web-resources-cdn

FROM nginx:stable-alpine
COPY --from=build /app/build/web/ /usr/share/nginx/html/
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --chmod=755 docker/write-api-url.sh /docker-entrypoint.d/40-write-api-url.sh
EXPOSE 80
