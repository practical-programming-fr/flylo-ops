# FlyLo local resolution demo — runbook

## What you have

| Path | Role |
| --- | --- |
| `../flylo-caller-app` | Voice Guest Care (Grok) |
| `../booking-backend` | Local API on `:8787` (mirror `practical-programming-fr/booking-backend`) |
| `../booking-frontend` | Booking UI on `:3002` |
| `../flylo-triage` | Webhook triage on `:4001` |
| `./` (flylo-ops) | Chatwoot `:3001` + Mailpit `:8025` |

**Note:** org forking is disabled on `flylo-air/*`. We cloned over HTTPS and pushed public mirrors to `practical-programming-fr/booking-backend` and `practical-programming-fr/booking-frontend` (GitHub Actions workflows omitted — OAuth token lacks `workflow` scope).

## Demo bug

`booking-backend` `main` / `demo/pricing-outage` returns **503** `PRICING_OUTAGE_DEMO` for `GET /v1/flights/search?from=LHR&to=CDG…` while `/v1/health` stays **200**.

## Start everything

```bash
# 1) Chatwoot + Mailpit
cd /Users/rayed/Workspace/flylo-ops
docker compose up -d
# first time only:
./scripts/prepare-db.sh
./scripts/bootstrap-demo.sh   # prints CHATWOOT_* — already wired into caller + triage .env

# 2) Booking backend (needs local Supabase)
cd /Users/rayed/Workspace/booking-backend
npx supabase start
export $(grep -v '^#' .env | xargs)   # or: node --env-file=.env …
npm run db:seed                       # first time / refresh
node --env-file=.env --import tsx src/server.ts

# 3) Booking frontend
cd /Users/rayed/Workspace/booking-frontend
npm run dev -- --port 3002

# 4) Triage
cd /Users/rayed/Workspace/flylo-triage
PORT=4001 npm run dev
# set CURSOR_API_KEY in .env for Cloud Agent launches

# 5) Voice caller
cd /Users/rayed/Workspace/flylo-caller-app
npm run dev   # :3000
```

Chatwoot admin (local): `admin@flylo.local` / `FlyloDemo123!` → http://localhost:3001

## Scripted demo

1. Confirm bug: open http://localhost:3002/search?from=LHR&to=CDG&date=2026-10-20&pax=1&cabin=L — search errors. Health http://localhost:8787/v1/health is OK.
2. Call Guest Care at http://localhost:3000 — escalate: *“I can’t search London to Paris; the booking site errors.”* Give name, email, phone.
3. Ticket lands in Chatwoot; webhook (or `TRIAGE_FALLBACK_URL`) hits triage.
4. Watch `flylo-triage` logs → GitHub issue on `practical-programming-fr/booking-backend` → Cursor Cloud Agent (needs `CURSOR_API_KEY`) → PR merge.
5. Pull fix locally and restart backend:
   ```bash
   cd /Users/rayed/Workspace/booking-backend
   git pull origin main
   # restart node server
   ```
6. Search LHR→CDG works again. Chatwoot conversation resolved; guest email in Mailpit http://localhost:8025.

## Env checklist

- Caller: `FLYLO_API_BASE_URL=http://localhost:8787`, local `CHATWOOT_*`, `TRIAGE_FALLBACK_URL=http://localhost:4001/hooks/ticket`
- Triage: `GITHUB_TOKEN`, `CURSOR_API_KEY`, Chatwoot token, `BOOKING_API_URL`, `BOOKING_WEB_URL=http://localhost:3002`

## Sharing with the team

Public booking mirrors (safe: only `.env.example` is committed; real `.env` / `.env.local` stay local):

- https://github.com/practical-programming-fr/booking-backend
- https://github.com/practical-programming-fr/booking-frontend

Local Chatwoot + Mailpit: clone https://github.com/practical-programming-fr/flylo-ops and follow its README (`docker compose up -d`, then prepare-db + bootstrap). After bootstrap:

- Chatwoot: http://localhost:3001 (`admin@flylo.local` / `FlyloDemo123!`)
- Mailpit: http://localhost:8025

Also clone/run `flylo-triage` and `flylo-caller-app` from whoever owns those workspaces; point their env at the local URLs in this runbook.

