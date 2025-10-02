# Stability and Current State Audit

This document records the current state of the project and serves as a checklist for ensuring stability before any changes are merged.

It is meant to be updated manually or by CI processes.  If a file or setting is added/removed, update the relevant section.

## 1. Project Overview
- **Repository root:** `workspaces/_init_1`
- **Primary technology stack** (extract from `Dockerfile` / `.dockerignore`):
  - Python 3.9‑3.11
  - FastAPI + Uvicorn (API server)
  - Docker Compose (for local dev & CI)
  - `pydantic` for config validation
  - `pydantic-core` for speed
  - `uvicorn` for ASGI

## 2. Config & Secrets
| File | Purpose | Notes |
|------|---------|-------|
| `.env.local` | Local environment overrides | Must be present for health checks
| `secrets/tls/ca.crt` | CA cert for HTTPS | Used by `01_health.sh`

### Secrets Checklist
- All keys are in environment variables or `.env` files and never committed.
- Certificate files are present and readable.
- No stray secrets in code or comments.

## 3. Docker Compose Services
Currently one service is defined:
| Service | Build context | Image | Ports | Volumes |
|---------|----------------|-------|-------|---------|
| `codex-cli` | `./containers/codex-cli` | <auto‑built> | none exposed | `./shared:/workspace` |

#### TODO
- Add a `proxy` service if needed.
- Define health check for Docker services.

## 4. Health Checks
Health scripts are located in `tests/acceptance`.  The primary script is `01_health.sh`.

#### Manual Run (requires Docker Compose environment)
```bash
docker compose up -d codex-cli
./tests/acceptance/01_health.sh
```

#### Checklist
- Verify `docker compose ps` lists all expected services.
- Ensure `curl` can reach `https://{SHS_DOMAIN}:{SHS_PROXY_PORT}/healthz`.
- `log` output should contain `pass` for `healthz ok`.

## 5. API Coverage
Search the repo for `fastapi` imports.  The primary API wrapper is in `./basement/toolbox/wrappers/rest`.

#### Endpoints to Verify
- `/healthz` – health check endpoint.
- `/docs` – Swagger UI.
  - Ensure it loads without errors.

## 6. Unit & Acceptance Tests
Test files:
- `tests/acceptance` – Integration tests using shell scripts.
- `tests/samples` – Sample input files for ingestion tests.

### Running Tests (where possible)
```bash
pytest -q
```

If `pytest` is not installed, you can install it locally:
```bash
pip install pytest
```

### Test Checklist
- All tests should pass with `pytest`.
- Scripts in `tests/acceptance` should exit with code `0` when services are healthy.

## 7. Logging & Observability
Logs are written to `logs/shs.jsonl` by the health script.

### Log Rotation
Ensure `logrotate` or equivalent rotates `logs/shs.jsonl`.

## 8. CI/CD Integration
The CI pipeline is defined under `./wardrobe/overlays/ci`.

#### Key Steps
1. Build Docker images.
2. Run unit tests.
3. Deploy to staging.

Verify that the CI YAML files reference the correct Docker Compose file and environment.

## 9. Security & Hardening
- No root users in containers.
- Environment variables are limited to required services.
- TLS settings are validated by the health script.
- Ensure no untrusted code is pulled from external sources.

## 10. Future Work
- Add a `backup` service for data persistence.
- Implement a metrics exporter.
- Expand unit tests for edge cases.

---

**Author:** Codex CLI Team
**Last updated:** `$(date -u +%Y-%m-%d)`
