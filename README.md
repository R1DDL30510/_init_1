# Secure Home Systems (SHS) Bootstrap Stack

> “Secure the house, illuminate the library, promote with confidence.” — SHS mantra

## Table of Contents
1. [Executive Overview](#executive-overview)
2. [Wayfinding & Documentation Legend](#wayfinding--documentation-legend)
3. [Repository Atlas](#repository-atlas)
4. [Documentation Portfolio](#documentation-portfolio)
5. [Operational Reference](#operational-reference)
6. [Acceptance Tests](#acceptance-tests)
7. [Change Management & Consolidation Roadmap](#change-management--consolidation-roadmap)
8. [Contributing Guidelines](#contributing-guidelines)

## Executive Overview
The SHS repository delivers a fully offline, TLS-enforced RAG pipeline that prioritizes determinism, GDPR alignment, and auditable operations. Docker Compose orchestrates proxy, OpenWebUI, n8n workflows, Postgres with pgvector, MinIO object storage, OCR, TEI embeddings, reranker, and optional Ollama services. All images and models are pinned through `VERSIONS.lock`, and `make` automation guards reproducible secrets, backups, and status reporting.

- **Primary strategy pillars**: local-first execution, least privilege, deterministic artifacts, structured observability, and fail-closed security posture.
- **Compliance tracking**: see [`docs/audit-matrix.md`](docs/audit-matrix.md) for a scored view against SHS principles and relevant industry expectations.

## Wayfinding & Documentation Legend
- **Start Here:** [`docs/project-compendium.md`](docs/project-compendium.md) — whole-house presentation with chapter legend, personas, and direct links into each layer.
- **Audit Readiness:** [`docs/pre-release-audit.md`](docs/pre-release-audit.md) — mapped controls, findings, and gating actions for Wardrobe → Entrance promotion (confidence 0.99).
- **Governance Blueprint:** Upcoming [`docs/house-governance.md`](docs/house-governance.md) will host dependency matrices; until then leverage the compendium and architecture guide.
- **Quote & Commentary:** Maintain inline quotes and call-outs across documentation to keep the narrative aligned with promotion discipline.

## Repository Atlas
| Layer | Path | Description | Reference |
| --- | --- | --- | --- |
| Fundament | [`fundament/`](fundament/) | Host baselines (Docker, Git) and promotion notes maintained outside the container stack. | [`docs/architecture.md`](docs/architecture.md) |
| Basement | [`basement/`](basement/) | Core service stubs plus the `toolbox/` mono-repo for catalogs, schemas, inventories, and compose drafts. | [`docs/revision-2025-09-28.md`](docs/revision-2025-09-28.md) |
| Wardrobe | [`wardrobe/`](wardrobe/) | Overlay profiles for CPU/GPU/CI parity and wrappers such as `gcodex`. | [`docs/architecture.md`](docs/architecture.md) |
| Entrance | [`entrance/`](entrance/) | Canary and telemetry planning surfaces awaiting promotion gates. | [`docs/revision-2025-09-28.md`](docs/revision-2025-09-28.md) |
| Stable | [`stable/`](stable/) | Production rollout skeletons with monitoring placeholders. | [`docs/revision-2025-09-28.md`](docs/revision-2025-09-28.md) |
| Operations | [`scripts/`](scripts/) | TLS tooling, backup/restore, status reporting, and acceptance orchestration. | [`RUNBOOK.md`](RUNBOOK.md) |
| Platform | [`compose.yaml`](compose.yaml) | Docker Compose stack with `minimal` and `gpu` profiles, strict health checks, and read-only enforcement. | [`SECURITY.md`](SECURITY.md) |
| Data | [`db/`](db/) | Postgres schema, pgvector indices, and RLS policies with least-privilege roles. | [`SECURITY.md`](SECURITY.md) |
| Tests | [`tests/`](tests/) | Acceptance suite emitting JSON logs with trace identifiers. | [`RUNBOOK.md`](RUNBOOK.md) |

## Documentation Portfolio
- [`docs/project-compendium.md`](docs/project-compendium.md): Whole-house guide that orients readers through the house metaphor, highlights personas, and maps each document to the appropriate layer.
- [`RUNBOOK.md`](RUNBOOK.md): operator lifecycle (bootstrap, start/stop, tests, backup/restore, rotations, incident handling). The runbook references Makefile targets directly to avoid duplicating procedural detail contained below.
- [`SECURITY.md`](SECURITY.md): threat model, control surface, and maintenance expectations aligned with TLS, RLS, and audit log requirements.
- [`docs/architecture.md`](docs/architecture.md): explains the house metaphor, current overlays, and planned flow between layers.
- [`docs/revision-2025-09-28.md`](docs/revision-2025-09-28.md): living snapshot of open planning tasks across layers, including promotion discipline updates (GA-04).
- [`docs/audit-matrix.md`](docs/audit-matrix.md): consolidated scoring of compliance against SHS strategic principles and broader industry standards (TLS, GDPR, observability, reproducibility).
- [`docs/pre-release-audit.md`](docs/pre-release-audit.md): pre-release audit (PoC confidence 0.99) summarizing evidence, gaps, and gating actions for Wardrobe → Entrance promotion with cross-links to the compendium legend.

## Operational Reference
### Quickstart
1. Copy the environment template and set secrets locally:
    ```bash
    cp .env.example .env.local
    sed -i 's/***FILL***/<value>/g' .env.local
    ```
2. Bootstrap directories, TLS assets, and guardrails:
    ```bash
    make bootstrap
    ```
3. Update `VERSIONS.lock` with verified image digests and model revisions.
4. Launch the stack (defaults to the `minimal` profile):
    ```bash
    make up
    ```
5. Inspect live status and health:
    ```bash
    make status
    ```

#### Profiles
- **minimal**: CPU-only deployment excluding Ollama; suitable for deterministic CI smoke checks.
- **gpu**: extends the stack with Ollama configured for NVIDIA runtimes. Enable via:
    ```bash
    docker compose --env-file .env.local --profile gpu up -d
    ```

### Environment Variables
Review `.env.example` for the full catalog; key highlights include:
- `SHS_BASE`, `SHS_DOMAIN`, `TLS_MODE`, `WATCH_PATH`, `LAN_ALLOWLIST`, `OFFLINE` — core bootstrap inputs.
- `POSTGRES_*`, `MINIO_*`, `N8N_*`, `OPENWEBUI_*` — service credentials sourced from host secrets.
- `*_IMAGE` entries — pinned container references synchronized with `VERSIONS.lock`.

### Deterministic TLS & Secrets
- `make bootstrap` calls `scripts/tls/gen_local_ca.sh` to mint a reproducible local CA (`secrets/tls/ca.crt`) and service leaf certificates (`secrets/tls/leaf.pem`).
- Rotate via `make ca.rotate`; all services fail closed if expected materials are missing.
- Secrets remain in `secrets/` or `.env.local` (git-ignored). The repository never stores production credentials.

### Observability & Traceability
- JSONL audit logs are written to `logs/shs.jsonl` with per-flow `trace_id` propagation.
- `scripts/status.sh` summarizes HTTPS endpoints, enabled profiles, version pins, and health-check results.
- Acceptance scripts log the executed command, exit status, and trace identifier for audit readiness.

### Data & Workflow Model
- Schema definitions in `db/schema.sql` implement `documents`, `chunks`, and `embeddings` with pgvector indexes.
- Row-level security policies in `db/policies.sql` grant `shs_app_r` and `shs_app_rw` least-privilege access.
- Ingestion, sync, and resilience flows live in `n8n/init_flows.json`, mirroring acceptance coverage.

## Acceptance Tests
Execute the entire suite once services pass readiness probes:
```bash
make test
```
Each script under `tests/acceptance/` emits structured JSON logs, verifying TLS-only proxy access, ingest idempotency, semantic answers with citations, SQL exact matches, sync reconciliation, and fault drill retries.

## Change Management & Consolidation Roadmap
- **Redundancy audit**: `docs/architecture.md` and `docs/revision-2025-09-28.md` intentionally overlap on layer roles. Future consolidation can merge them into a single “Architecture & Roadmap” compendium when day-to-day planning stabilizes.
- **Operational runbooks**: `RUNBOOK.md` retains lifecycle commands while deferring in-depth rationale to this README and the audit matrix. Additional procedure detail (e.g., mirror sync playbooks) should land in `docs/` rather than duplicating sections across files.
- **Security references**: `SECURITY.md` is the canonical control register. Avoid scattering control descriptions into service READMEs to maintain a single source of truth.
- **Placeholder directories**: `wardrobe/`, `entrance/`, and `stable/` currently house planning scaffolds only; evaluate quarterly whether they can be merged or promoted into the Compose stack.

## Contributing Guidelines
- Maintain two-space indentation for YAML and four-space-indented Markdown code fences.
- Document architecture or operational changes in the referenced files above before committing automation or service updates.
- Use imperative commit messages referencing affected layers (e.g., `Align basement documentation map`).
- Never commit secrets; mirror new dependencies into `fundament/versions.yaml` or `basement/toolbox/inventories/` before release.
