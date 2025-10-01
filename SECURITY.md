# Secure Home Systems Security Overview

This document centralizes the security posture for SHS and links each control to the compliance scoring maintained in [`docs/audit-matrix.md`](docs/audit-matrix.md). It complements the operational guidance in [`RUNBOOK.md`](RUNBOOK.md) and the architectural framing in [`docs/architecture.md`](docs/architecture.md).

## Threat Model
- **Actors**: authenticated operators, local OS accounts, malicious LAN peers, compromised workloads.
- **Assets**: documents stored in MinIO/Postgres, TLS CA material, orchestrator credentials, audit logs, and n8n flow definitions.
- **Trust Boundaries**:
  - Reverse proxy terminates TLS, enforces LAN allow-lists, and negotiates mTLS with internal services where supported.
  - Internal services communicate strictly across the `shs_net` overlay network with least-privilege Docker users.
  - Secrets remain under `secrets/` and `.env.local`; backups produced by `make backup` are encrypted offline.
- **Assumptions**: host filesystem encryption is enabled, Docker Engine is patched, and operators use least-privilege accounts with hardware-backed MFA.

## Control Catalog
1. **Transport Security**
    - Deterministic local CA generation via `scripts/tls/gen_local_ca.sh` with mandatory HSTS and no HTTP fallback.
    - Proxy enforces modern TLS ciphers and request rate limits; see `proxy/Caddyfile` for headers and mTLS configuration.
2. **Authentication & Authorization**
    - OpenWebUI runs with local authentication and telemetry disabled (`services/openwebui/config.yaml`).
    - Postgres implements row-level security with `shs_app_r` (read) and `shs_app_rw` (read/write) roles defined in `db/policies.sql`.
    - MinIO access keys are injected from host secrets; lifecycle automation refuses to start when placeholders remain.
3. **Data Lifecycle**
    - Ingestion workflows hash content with SHA-256, store raw files in MinIO, and persist metadata in Postgres (`n8n/init_flows.json`).
    - Soft deletes populate `deleted_at` while acceptance tests confirm convergence between MinIO and Postgres.
    - Backups captured via `make backup` include TLS, logs, version pins, and a pg_dump snapshot for deterministic restores.
4. **Observability & Audit**
    - All services log in JSON with `trace_id` propagation; acceptance tests assert logging integrity.
    - `scripts/status.sh` reports health endpoints and compares running versions to `VERSIONS.lock`.
    - Audit artifacts map to GDPR purposes; operators record deletions and accesses in `logs/shs.jsonl`.
5. **Resilience & Fail-Closed Behaviour**
    - `make` targets validate secret placeholders and certificate existence before launching services.
    - Health checks in `compose.yaml` gate readiness; failure to pass results in automatic restart loops, avoiding silent degradation.
    - Resilience drills in `tests/acceptance/06_resilience.sh` confirm retry logic and trace continuity.

## Maintenance Expectations
- Rotate the CA quarterly or after compromise using `make ca.rotate` and redeploy via `make up`.
- Update container digests in `VERSIONS.lock` before applying image changes; track decisions in `docs/revision-2025-09-28.md`.
- Mirror dependency adjustments in `fundament/versions.yaml` (host) or `basement/toolbox/inventories/` (project) prior to promotion.
- For new controls or exceptions, update this document and adjust the scoring in [`docs/audit-matrix.md`](docs/audit-matrix.md) to reflect the current state.
