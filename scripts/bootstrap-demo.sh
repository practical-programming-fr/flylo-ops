#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

TRIAGE_URL="${TRIAGE_WEBHOOK_URL:-http://host.docker.internal:4001/webhooks/chatwoot}"
ADMIN_EMAIL="${CHATWOOT_ADMIN_EMAIL:-admin@flylo.local}"
ADMIN_PASSWORD="${CHATWOOT_ADMIN_PASSWORD:-FlyloDemo123!}"
ACCOUNT_NAME="${CHATWOOT_ACCOUNT_NAME:-FlyLo Demo}"

docker compose cp scripts/bootstrap_demo.rb rails:/tmp/bootstrap_demo.rb
docker compose exec -T \
  -e "TRIAGE_WEBHOOK_URL=${TRIAGE_URL}" \
  -e "CHATWOOT_ADMIN_EMAIL=${ADMIN_EMAIL}" \
  -e "CHATWOOT_ADMIN_PASSWORD=${ADMIN_PASSWORD}" \
  -e "CHATWOOT_ACCOUNT_NAME=${ACCOUNT_NAME}" \
  rails bundle exec rails runner /tmp/bootstrap_demo.rb
