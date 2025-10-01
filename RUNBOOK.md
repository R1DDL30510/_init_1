# Secure Home Systems Runbook

This runbook is the operational companion to the repository atlas in [`README.md`](README.md). It references the same automation targets defined in the `Makefile` while pointing to authoritative documentation for architecture, security, and audit scoring.

## Prerequisites
- Docker Engine 24+ with compose plugin and access to the host Docker socket.
- Host packages: OpenSSL, `zstd`, `jq`, `age`, and `psql` as recorded in [`fundament/versions.yaml`](fundament/versions.yaml).
- Local secrets populated in `.env.local` using `.env.example` as a template; never commit credentials.

## Bootstrap Sequence
1. Launch the Dev Container (`.devcontainer/devcontainer.json`) or prepare equivalent host tooling.
2. Execute `make bootstrap` to:
    - generate deterministic CA and leaf certificates via `scripts/tls/gen_local_ca.sh`,
    - scaffold `logs/` and `backups/`,
    - copy `.env.example` into `.env.local` when absent.
3. Validate `VERSIONS.lock` contains the intended image tags, digests, and model metadata referenced by `compose.yaml` and service configs.

## Lifecycle Commands
| Action | Command | Notes |
| --- | --- | --- |
| Start services | `make up` | Defaults to the `minimal` profile; pass `PROFILE=gpu` to target the GPU overlay. |
| Stop services | `make down` | Leaves persistent volumes intact; use `docker compose down -v` manually for destructive cleanup. |
| Status summary | `make status` | Calls `scripts/status.sh` to report HTTPS endpoints, enabled profiles, and health probe results. |
| Acceptance suite | `make test` | Runs all scripts under `tests/acceptance/` with trace-aware JSON logging. |
| Rotate CA | `make ca.rotate` | Forces deterministic regeneration of CA/leaf materials; rerun `make up` afterwards. |
| Backup | `make backup` | Produces `backups/shs-<timestamp>.tar.zst` containing TLS, logs, versions, and a Postgres dump. |
| Restore | `make restore ARCHIVE=...` | Stops services, restores archive content, and replays database dump. |
| Clean | `make clean` | Removes generated TLS assets, logs, backups, and the local env file. |

## Acceptance Testing
- Follow the execution order defined in `tests/acceptance/*.sh`; each script logs to `logs/shs.jsonl` with a dedicated `trace_id`.
- The suite asserts TLS-only proxy availability, ingest idempotency, semantic retrieval with ≥3 citations, SQL accuracy, sync reconciliation, and resilience retry paths.
- Reference [`docs/audit-matrix.md`](docs/audit-matrix.md) to map each test to the associated compliance principle.

## Backup & Restore Procedures
1. Ensure services are healthy (`make status`).
2. Run `make backup` and store the resulting archive offline.
3. For restoration, provide the archive path: `make restore ARCHIVE=backups/shs-<timestamp>.tar.zst`.
4. After restore, execute `make up` followed by `make status` to confirm certificates, digests, and health checks align with `README.md` expectations.

## Incident Response Checklist
- Immediately restrict access by tightening `LAN_ALLOWLIST` in `.env.local` and re-running `make up`.
- Rotate certificates (`make ca.rotate`) and regenerate secrets as necessary.
- Capture evidentiary logs (`cp logs/shs.jsonl incident-<timestamp>.jsonl`) and verify database integrity with the SQL probes documented in [`db/policies.sql`](db/policies.sql).
- Use the control matrix in [`SECURITY.md`](SECURITY.md) to confirm containment steps.

## Change Management Notes
- Document model updates in both the relevant service config (`services/tei/config.yaml`, `services/reranker/config.yaml`) and `VERSIONS.lock` before restarting services.
- Any new automation or overlay should first be described in `docs/architecture.md` and, if security-related, cross-referenced in `SECURITY.md`.
- For planned restructuring (e.g., merging `docs/architecture.md` and `docs/revision-2025-09-28.md`), log the proposal in the latter file’s “Cross-Layer Tasks” section.
