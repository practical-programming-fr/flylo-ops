#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
echo "Chatwoot DB prepared."
