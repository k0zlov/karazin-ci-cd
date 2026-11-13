#!/bin/sh
set -eu

printf '%s\n' "${API_BASE_URL:-}" > /usr/share/nginx/html/runtime-api-url.txt
