#!/bin/sh
set -eu

printf '%s\n' "${API_BASE_URL:-}" > /usr/share/nginx/html/api-base-url.txt
