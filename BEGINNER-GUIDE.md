# Beginner Guide: What You're Looking At

## Quick Start

1. Run `mm.bat doctor`.
2. If doctor reports Docker/service/engine failure, run `mm.bat repair`.
3. Run `mm.bat start`.
4. Use `mm.bat stop` when done.

Alternative (menu):
1. Run `dev-control.bat`.
2. Pick `7` (Doctor) first.
3. If needed, pick `8` (Repair Docker runtime).
4. Pick `1` (Start everything).

## Mental Model (Simple)

- `Docker containers`:
  - `postgres`: stores data
  - `redis`: message queue
- `SEO API`:
  - main web app on `http://localhost:8000`
- `Pain Miner API`:
  - health endpoint on `http://localhost:8100/healthz`
  - dashboard on `http://localhost:8100/dashboard`
- `Workers`:
  - background processors (they do scheduled jobs)

Seeing only Postgres/Redis logs in Docker is normal. It just means infra is alive.
The APIs and workers run from local Python processes, so check them with `status-dev.bat`.

## Useful Commands

- Unified command runner: `mm.bat help`
- Start stack: `mm.bat start`
- Status: `mm.bat status`
- Doctor: `mm.bat doctor`
- Repair Docker runtime: `mm.bat repair`
- Logs: `mm.bat logs`
- Stop: `mm.bat stop`
- One-click run: `run-app.bat`
- Control center menu: `dev-control.bat`
- Start all: `easy-start.bat`
- Start advanced: `start-dev.bat`
- Check health: `status-dev.bat`
- Watch all logs live: `watch-dev-logs.bat`
- Trigger pipeline now: `run-daily-now.bat`
- Run free-profit GTM workflow: `run-free-profit-day.bat`
- Stop all: `stop-dev.bat`
- Free-profit command mode: `mm.bat profit -Date YYYY-MM-DD -DailyTouches 20`
- Ops console page: `http://localhost:8000/internal/autopilot-console`
  - Can now trigger `Fast` or `Full` autopilot runs from the browser and see run status/log tail.

## Code Quality Commands

- Install dev dependencies (includes `pytest` and `ruff`):
  - `cd seo-rank-tracker`
  - `.venv\Scripts\python -m pip install -e ".[dev]"`
- Run lint checks:
  - `cd seo-rank-tracker`
  - `.venv\Scripts\python -m ruff check app tests`
- Run tests:
  - `cd seo-rank-tracker`
  - `.venv\Scripts\python -m pytest -q`

## Production Infra Template

- Root infra file: `docker-compose.prod.yml`
- Copy `.env.prod.example` to `.env.prod` and set strong passwords.
- Start prod-style infra:
  - `docker compose --env-file .env.prod -f docker-compose.prod.yml up -d`

## Failure Map (Fast)

- Error: `Docker CLI was not found.`
  - Run: install Docker Desktop, then `mm.bat doctor`
- Error: `Docker service start was denied or failed.`
  - Run: `mm.bat repair` and approve UAC prompt
- Error: `Docker engine did not become ready...`
  - Run: `mm.bat repair`
- Error: `compose startup failed or timed out.`
  - Run: `mm.bat doctor`, then `mm.bat repair`
- Error: `SEO API did not become healthy` or `Pain Miner API did not become healthy`
  - Run: `mm.bat logs`

## Where Errors Show Up

In `logs\`:

- `logs\seo-api.log`
- `logs\seo-worker.log`
- `logs\pm-api.log`
- `logs\pm-worker.log`
- `logs\pm-beat.log`

## Success Checklist

- `status-dev.bat` shows containers `Up`
- `http://localhost:8000/openapi.json` returns `200`
- `http://localhost:8100/healthz` returns `200`
