# FlyLo ops — local Chatwoot + Mailpit

Docker Compose stack for the FlyLo Guest Care demo: self-hosted **Chatwoot** (tickets + email) and **Mailpit** (local SMTP inbox).

Related public repos:

- [practical-programming-fr/booking-backend](https://github.com/practical-programming-fr/booking-backend)
- [practical-programming-fr/booking-frontend](https://github.com/practical-programming-fr/booking-frontend)

For the full end-to-end demo (voice caller, booking bug, triage, Cloud Agent), see [`DEMO_RUNBOOK.md`](./DEMO_RUNBOOK.md).

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose v2)
- Ports free on the host: `3001`, `8025`, `1025`, `5433`, `6380`

## Quick start

```bash
git clone https://github.com/practical-programming-fr/flylo-ops.git
cd flylo-ops

cp .env.example .env

docker compose up -d

# First time only — prepare the Chatwoot database
./scripts/prepare-db.sh

# First time only — create admin, account, email inbox, API token, webhook
./scripts/bootstrap-demo.sh
```

Bootstrap prints `CHATWOOT_*` values. Copy them into the caller app / triage service env if you run those locally.

## URLs & default login

| Service | URL |
| --- | --- |
| Chatwoot | http://localhost:3001 |
| Mailpit | http://localhost:8025 |
| Postgres | `localhost:5433` |
| Redis | `localhost:6380` |
| SMTP (Mailpit) | `localhost:1025` |

After bootstrap:

- **Email:** `admin@flylo.local`
- **Password:** `FlyloDemo123!`

Override via env when running bootstrap:

```bash
CHATWOOT_ADMIN_EMAIL=you@example.com \
CHATWOOT_ADMIN_PASSWORD='choose-a-password' \
./scripts/bootstrap-demo.sh
```

## Webhook (optional)

By default, bootstrap registers a Chatwoot account webhook pointing at:

`http://host.docker.internal:4001/webhooks/chatwoot`

That expects `flylo-triage` listening on the host at port `4001`. Override with:

```bash
TRIAGE_WEBHOOK_URL=http://host.docker.internal:4001/webhooks/chatwoot \
./scripts/bootstrap-demo.sh
```

On Linux, if `host.docker.internal` is unavailable, use your host LAN IP or add it in Compose.

## Day-to-day

```bash
# start
docker compose up -d

# logs
docker compose logs -f rails

# stop (keeps volumes / data)
docker compose down

# wipe data and start clean
docker compose down -v
cp .env.example .env   # if needed
docker compose up -d
./scripts/prepare-db.sh
./scripts/bootstrap-demo.sh
```

## Notes

- Signup is enabled (`ENABLE_ACCOUNT_SIGNUP=true`) so local bootstrap can create the admin account.
- Outbound Chatwoot mail is sent to Mailpit — open http://localhost:8025 to read guest emails after a ticket is resolved.
- `.env` is gitignored. Commit only `.env.example`.
- This stack is for **local demos only**, not production.
