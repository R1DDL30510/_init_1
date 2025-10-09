# Secure Home Systems (SHS) Bootstrap Stack

> "Secure the house, illuminate the library, promote with confidence."

## Table of Contents
- [High-Level Overview](#high-level-overview)
- [Architecture at a Glance](#architecture-at-a-glance)
- [Repository Layout](#repository-layout)
- [Operational Playbook](#operational-playbook)
- [Documentation & Audits](#documentation--audits)
- [Maintenance & Supply Chain](#maintenance--supply-chain)
- [Contribution Guidelines](#contribution-guidelines)
- [Glossary](#glossary)

## High-Level Overview
Secure Home Systems (SHS) delivers an offline-first retrieval-augmented generation (RAG) stack that runs entirely on dedicated hardware. Content ingestion, storage, retrieval, and response generation are orchestrated through Docker Compose profiles defined in [`compose.yaml`](compose.yaml). The platform enforces transport security, deterministic configuration, and auditable operations so regulated teams can operate large language model assistants on-premises.

Core capabilities include:
- **Secure access:** A hardened reverse proxy terminates TLS and enforces allow-lists defined in [`proxy/Caddyfile`](proxy/Caddyfile) while certificates are minted locally through [`scripts/tls/gen_local_ca.sh`](scripts/tls/gen_local_ca.sh).
- **Document lifecycle:** OCR, text enrichment, and reranking services under [`services/`](services) transform source files into structured content held in Postgres with pgvector (`db/`) and MinIO object storage (`compose.yaml`).
- **Operator workflows:** OpenWebUI and n8n (also provisioned in `compose.yaml`) provide conversational access and automation with telemetry disabled and least privilege defaults (`services/openwebui/config.yaml`, [`n8n/init_flows.json`](n8n/init_flows.json)).
- **Optional generation:** GPU-enabled environments can extend the baseline by activating the `gpu` profile to reach a co-located Ollama runtime.

## Architecture at a Glance
The stack is organised around four pillars:

1. **Ingestion & Processing** – Container definitions for OCR, Text Extraction Interface (TEI), and reranking live in [`services/ocr`](services/ocr), [`services/tei`](services/tei), and [`services/reranker`](services/reranker). These services rely on shared configuration files and export health endpoints enforced through Compose health checks.
2. **Storage & Indexing** – [`db/schema.sql`](db/schema.sql) and [`db/policies.sql`](db/policies.sql) initialise Postgres with vector-enabled tables and row-level security, while MinIO acts as the binary object store (configured in `compose.yaml`).
3. **Application & Automation** – OpenWebUI and n8n use configuration overlays and seed flows (`services/openwebui/config.yaml`, `n8n/init_flows.json`) to surface curated retrieval pipelines and scheduled tasks. Profiles declared in `compose.yaml` let operators toggle GPU resources without rewriting manifests.
4. **Security & Observability** – TLS assets are generated on demand (`make bootstrap`) and audited through [`scripts/status.sh`](scripts/status.sh). Proxy access logs and service traces land under `logs/` once the stack is running, while compliance controls are documented in [`SECURITY.md`](SECURITY.md).

## Repository Layout
| Path | Purpose | Key Artifacts |
| --- | --- | --- |
| [`basement/`](basement/) | Service blueprints, drafts, and tooling experiments that inform production images. | `g-ollama/`, `g-openwebui/`, `toolbox/` prototypes |
| [`docs/`](docs/) | Authoritative documentation, diagrams, and audit notes. | `architecture.md`, `project-compendium.md`, `repository-map.md`, `audits/` |
| [`entrance/`](entrance/) | Canary environments and telemetry gates used before promoting builds downstream. | `canary/`, `telemetry/`, `README.md` |
| [`fundament/`](fundament/) | Host-level bootstrap assets such as Docker daemon preferences, verification scripts, and version manifests. | `versions.yaml`, `docker/`, `scripts/`, `STATE_VERIFICATION.md` |
| [`n8n/`](n8n/) | Seed workflow definitions imported during service start. | `init_flows.json` |
| [`proxy/`](proxy/) | Reverse proxy policy and security headers. | `Caddyfile` |
| [`scripts/`](scripts/) | Operational shell utilities for TLS generation, supply-chain inventory, backups, status reporting, and validation. | `tls/`, `backup.sh`, `status.sh`, `discover_components.sh` |
| [`services/`](services/) | Build contexts and runtime configuration for first-party containers. | `ocr/`, `tei/`, `reranker/`, `openwebui/` |
| [`stable/`](stable/) | Production-ready host overlays and monitoring scaffolding. | `host1/`, `host2/`, `monitoring/`, `README.md` |
| [`tests/`](tests/) | Acceptance scripts executed via `make test` to validate end-to-end behaviour and traceability. | `acceptance/*.sh` |
| [`wardrobe/`](wardrobe/) | Hardware profiles, overlays, and wrapper scripts for tailoring deployments to specific environments. | `configs/`, `overlays/`, `wrappers/`, `README.md` |
| [`db/`](db/) | SQL assets applied to Postgres during container initialisation. | `schema.sql`, `policies.sql` |
| [`locks/`](locks/) | Pinned dependency manifests for container images and Python wheels. | `VERSIONS.lock`, `REQUIREMENTS.lock.txt` |
| [`vendor/`](vendor/) | Download cache for models and wheel artifacts populated by the supply-chain workflow. | `models/`, `wheels/` |
| [`compose.yaml`](compose.yaml) | Declarative definition of all runtime services with `minimal` and `gpu` profiles. | — |
| [`Makefile`](Makefile) | Primary task runner covering bootstrap, lifecycle commands, testing, and backup/restore operations. | — |
| [`RUNBOOK.md`](RUNBOOK.md) | Operational runbook for day-to-day usage, incident handling, and recovery. | — |
| [`RUN.md`](RUN.md) | Step-by-step instructions for executing the supply-chain verification pipeline. | — |
| [`SECURITY.md`](SECURITY.md) | Security posture, threat model, and mapped controls. | — |
| [`STABILITY_AUDIT.md`](STABILITY_AUDIT.md) | Historical stability notes – review before release to ensure references align with the current Compose topology. | — |
| [`PRE_RELEASE_AUDIT.md`](PRE_RELEASE_AUDIT.md) | Pre-release scoring framework that tracks outstanding actions per domain. | — |

> **Note:** The `_init_1/` directory contains a bootstrapped copy of this repository used for deterministic workspace initialisation. It mirrors the top-level layout and inherits the same documentation and operational workflows.

## Operational Playbook
1. **Prepare the environment**
   ```bash
   cp .env.example .env.local
   make bootstrap
   ```
   `make bootstrap` validates the workspace (`scripts/validate_workspace.sh`), provisions TLS material under `secrets/tls/`, and creates secure log locations.
2. **Launch the stack**
   ```bash
   make up            # defaults to PROFILE=minimal
   PROFILE=gpu make up
   ```
   Compose profiles control whether Ollama (GPU) resources are activated. All services expose health checks so `docker compose` blocks on readiness.
3. **Inspect status and logs**
   ```bash
   make status
   docker compose logs -f proxy
   ```
   Status reports include TLS fingerprint summaries and service reachability via [`scripts/status.sh`](scripts/status.sh).
4. **Run validation tests**
   ```bash
   make test
   ```
   Acceptance scripts in [`tests/acceptance/`](tests/acceptance) exercise secure access, ingestion, retrieval, and traceability flows.
5. **Manage secrets and backups**
   ```bash
   make backup
   make restore ARCHIVE=/path/to/archive
   make ca.rotate
   ```
   Backup and restore targets wrap `scripts/backup.sh` and `scripts/restore.sh`. Certificate rotation reuses the bootstrap path to issue new credentials without manual edits.

## Documentation & Audits
- [`docs/architecture.md`](docs/architecture.md) – Conceptual model of the "house" metaphor, integration points, and roadmap decisions.
- [`docs/project-compendium.md`](docs/project-compendium.md) – Stakeholder-oriented catalogue covering each operational area.
- [`docs/repository-map.md`](docs/repository-map.md) – Authoritative directory index with validation hooks and automation notes.
- [`docs/audit-matrix.md`](docs/audit-matrix.md) – Compliance tracking sheet that aligns controls to responsible owners and review cadences.
- [`docs/revision-2025-09-28.md`](docs/revision-2025-09-28.md) – Workstream tracker for upcoming releases and environment transitions.
- [`docs/house-governance.md`](docs/house-governance.md) – Decision records, escalation paths, and approval checkpoints.
- [`docs/stack-plan-review.md`](docs/stack-plan-review.md) – Evaluates proposed changes to image pinning and deployment sequencing.
- [`docs/runbook-ga-02-delete-playbook.md`](docs/runbook-ga-02-delete-playbook.md) – Template for future deletion drills and data subject requests.

## Maintenance & Supply Chain
- **Version pinning** – Maintain container image digests and artifact metadata in [`locks/VERSIONS.lock`](locks/VERSIONS.lock). Python wheels are frozen in [`locks/REQUIREMENTS.lock.txt`](locks/REQUIREMENTS.lock.txt) and mirrored under [`vendor/wheels/`](vendor/wheels).
- **Inventory refresh** – [`RUN.md`](RUN.md) documents the end-to-end sequence (`make vendor-verify`, `make lock`, `make sbom`, `make audit`, `make split-repos`). These targets call scripts in [`scripts/`](scripts/) to regenerate Software Bills of Materials (SBOMs) and vulnerability scans.
- **Workspace verification** – [`verify.sh`](verify.sh) bootstraps stub tooling to assert repository invariants, ensuring discovery scripts behave consistently across environments.
- **Host hardening** – [`fundament/`](fundament/) captures Docker daemon policies, baseline state verification (`STATE_VERIFICATION.md`), and bootstrap helpers consumed during initial provisioning.

## Contribution Guidelines
- Document architectural or operational changes before shipping code. Update the relevant files in [`docs/`](docs/) alongside configuration updates.
- Use imperative commit messages (e.g., `Add GPU profile hardening`). Keep secrets out of Git history; sensitive values belong in `.env.local` or the `secrets/` tree ignored by Git.
- When altering Compose services or scripts, run `make test` locally once all dependencies are available to validate acceptance coverage.
- YAML files use two-space indentation and Markdown code blocks prefer fenced syntax with explicit languages.

## Glossary
| Term | Definition |
| --- | --- |
| **RAG (Retrieval-Augmented Generation)** | Pattern that retrieves relevant documents (`db/`, `services/tei`) before generating responses to ground model output. |
| **Compose Profile** | Named configuration set (`minimal`, `gpu`) in [`compose.yaml`](compose.yaml) used to toggle optional services like Ollama. |
| **pgvector** | Postgres extension enabling similarity search over embeddings created during ingestion; initialised through `db/schema.sql`. |
| **MinIO** | Self-hosted S3-compatible object store for document binaries and derived assets, declared as the `minio` service in `compose.yaml`. |
| **OpenWebUI** | Web front-end for interacting with the assistant, configured by [`services/openwebui/config.yaml`](services/openwebui/config.yaml). |
| **n8n** | Workflow automation engine seeded by [`n8n/init_flows.json`](n8n/init_flows.json) to orchestrate imports and sync jobs. |
| **age** | Modern encryption tool leveraged in `make backup` to protect archives produced by [`scripts/backup.sh`](scripts/backup.sh). |
| **Trace ID** | Unique identifier recorded in JSONL logs (see `logs/`) and surfaced by acceptance tests to correlate requests end-to-end. |
