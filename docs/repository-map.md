# SHS Repository Map & Validation Ledger

This atlas consolidates every directory and governance artifact currently tracked in Secure Home Systems (SHS). It cross-links each layer to the operating procedures, automation targets, and audit evidence that keep the stack reproducible. Use it as the canonical map when assessing documentation drift, updating digests, or preparing audit packages.

## How to use this map
- Start with the top-level index for a fast orientation, then drill into the dedicated sections for detailed responsibilities, validation hooks, and open follow-ups.
- Keep this document updated whenever new folders or controls appear; mirror the same references in the README atlas and the project compendium.
- Flag stale material directly in the "Outdated or superseded artifacts" section so remediation tasks can be scheduled instead of silently diverging from reality.

## Top-level index
| Path | Purpose | Canonical references | Validation & automation |
| --- | --- | --- | --- |
| `README.md` | Operator atlas explaining the house metaphor, service roster, onboarding flow, and newcomer doc catalogue. | 【F:README.md†L5-L167】 | `make status` highlights the same service set and digests for quick drift detection.【F:scripts/status.sh†L118-L134】 |
| `compose.yaml` | Production bootstrap stack for proxy, OpenWebUI, n8n, Postgres, MinIO, OCR, TEI, reranker, and GPU Ollama profiles. | 【F:compose.yaml†L1-L244】 | Health checks and GPU bindings enforced directly via Compose definitions.【F:compose.yaml†L15-L233】 |
| `.env.example` | Digest-pinned environment template operators copy to `.env.local` before running `make bootstrap`. | 【F:.env.example†L1-L64】 | `make bootstrap` copies this file, enforces permissions, and generates TLS material.【F:Makefile†L14-L24】 |
| `locks/VERSIONS.lock` | Source of truth for container image references, digests, model metadata, and schema integrity hashes. | 【F:locks/VERSIONS.lock†L1-L43】 | `make lock`, `make sbom`, and `make audit` regenerate lock data, SBOMs, and scan artefacts.【F:Makefile†L95-L166】【F:scripts/build_lock.py†L1-L42】【F:scripts/sbom_generate.sh†L1-L29】【F:scripts/audit.sh†L1-L34】 |
| `Makefile` | Workflow entrypoint for bootstrap, lifecycle management, supply-chain checks, and backup/restore targets. | 【F:Makefile†L14-L200】 | Acceptance suite iterates every script under `tests/acceptance/` to validate TLS-only access, ingest flows, and resilience.【F:Makefile†L36-L51】【F:tests/acceptance/01_health.sh†L1-L28】【F:tests/acceptance/06_resilience.sh†L1-L30】 |
| `Makefile.local` | Developer helper for building service images locally, populating wheelhouses/models, and running an ephemeral registry. | 【F:Makefile.local†L1-L34】 | Invokes `scripts/build_wheelhouse.sh` and `scripts/fetch_models.sh` to refresh vendor artefacts with recorded checksums.【F:Makefile.local†L12-L25】【F:scripts/build_wheelhouse.sh†L1-L28】【F:scripts/fetch_models.sh†L1-L34】 |
| `RUNBOOK.md` | Operational handbook covering bootstrap, TLS lifecycle, acceptance suite, backup/restore, and incident response. | 【F:RUNBOOK.md†L1-L87】【F:RUNBOOK.md†L36-L87】 | References `scripts/status.sh`, service configs, and acceptance evidence to keep operations and compliance in sync.【F:RUNBOOK.md†L36-L87】【F:scripts/status.sh†L118-L134】 |
| `SECURITY.md` | Centralised control register mapping threats, mitigations, and maintenance expectations to the audit matrix. | 【F:SECURITY.md†L1-L39】 | Align changes with scores in `docs/audit-matrix.md`; update both documents together during control revisions.【F:docs/audit-matrix.md†L1-L38】 |
| `RUN.md` | Supply-chain quickstart for `make lock → make sbom → make audit → make split-repos` runs across macOS, Ubuntu, and Windows. | 【F:RUN.md†L1-L28】 | Matches the supply-chain targets defined in `Makefile`, ensuring reproducible SBOM and scan execution.【F:Makefile†L95-L166】 |
| `STABILITY_AUDIT.md` | Legacy stability checklist referencing a pre-house toolbox layout; kept for historical context. | 【F:STABILITY_AUDIT.md†L9-L45】 | Flagged as outdated in this map; align with current Compose stack before reuse. |
| `PRE_RELEASE_AUDIT.md` | Early audit scoring doc predating the house consolidation; contains now-obsolete structure recommendations. | 【F:PRE_RELEASE_AUDIT.md†L1-L40】 | Treat recommendations as superseded by `docs/audit-matrix.md` and this repository map. |
| `verify.sh` | Offline verification harness that fakes SBOM tools, ensures directory presence, and checks discovery/lock flows. | 【F:verify.sh†L1-L61】【F:verify.sh†L62-L120】 | Useful for CI smoke tests when real scanners are unavailable; complements `scripts/status.sh --check-digests`. |

## Layer directories

### Fundament (`fundament/`)
- Captures host baselines (macOS 26.0 arm64, Docker Desktop 4.47.0, Git 2.50.1) and promotion notes before container orchestration.【F:fundament/README.md†L1-L12】【F:fundament/versions.yaml†L1-L20】
- `STATE_VERIFICATION.md` defines draft host checks (`docker version`, `git --version`) and upcoming promotion gates, keeping automation on hold until design reviews finish.【F:fundament/STATE_VERIFICATION.md†L1-L25】
- Use Runbook prerequisites to keep host requirements consistent with Fundament records.【F:RUNBOOK.md†L5-L18】

### Basement (`basement/`)
- Houses service stubs (g-ollama, g-openwebui) and the toolbox mono-repo for future Compose experiments.【F:basement/README.md†L1-L7】【F:basement/g-ollama/README.md†L1-L4】【F:basement/g-openwebui/README.md†L1-L4】
- `toolbox/` enumerates planned catalogues, inventories, wrappers (`bin/gcodex`), and Compose drafts; remains a planning sandbox without production artefacts.【F:basement/toolbox/README.md†L1-L23】
- External stack-pinning proposals are reconciled via `docs/stack-plan-review.md`, which anchors enhancements to the maintained lockfile and Make targets.【F:docs/stack-plan-review.md†L1-L58】

### Wardrobe (`wardrobe/`)
- Overlay staging area for CPU/GPU/CI variants; documents shared configuration templates and wrappers without committing final secrets.【F:wardrobe/README.md†L1-L6】【F:wardrobe/configs/README.md†L1-L3】
- Promotion expectations and parity goals are cross-referenced in the revision log and audit matrix.【F:docs/revision-2025-09-28.md†L20-L34】【F:docs/audit-matrix.md†L25-L33】

### Entrance (`entrance/`)
- Placeholder for canary rollouts and telemetry experiments pending Wardrobe promotion; readiness tracked in revision log tasks.【F:entrance/README.md†L1-L12】【F:docs/revision-2025-09-28.md†L35-L43】
- Subdirectories `canary/` and `telemetry/` describe rollout criteria and metrics without storing live data.【F:entrance/canary/README.md†L1-L3】【F:entrance/telemetry/README.md†L1-L3】

### Stable (`stable/`)
- Production skeleton with host allocations, monitoring placeholders, and observability planning awaiting promotion sign-off.【F:stable/README.md†L1-L5】【F:stable/host1/README.md†L1-L3】【F:stable/monitoring/README.md†L1-L3】
- Continue to log promotion gating in the revision roadmap before populating these directories with live configs.【F:docs/revision-2025-09-28.md†L44-L58】

## Platform services & configuration
- `compose.yaml` ties all runtime services together, enforcing TLS-only proxy access, Postgres schema mounts, MinIO TLS injection, health checks, and GPU-exclusive Ollama profile.【F:compose.yaml†L1-L233】
- Service-specific configurations live under `services/` and mirror the endpoints exposed by Compose:
  - OCR pipeline settings (MinIO credentials, language caps, trace headers).【F:services/ocr/config.yaml†L1-L20】
  - TEI embedding server dimensions, worker counts, and tracing headers.【F:services/tei/config.yaml†L1-L15】
  - Reranker scoring limits and health probes.【F:services/reranker/config.yaml†L1-L12】
  - OpenWebUI authentication and RAG endpoints back through the proxy.【F:services/openwebui/config.yaml†L1-L16】
- Custom Dockerfiles pin Python base images and rely on vendored wheels/models for deterministic builds.【F:services/ocr/Dockerfile†L1-L22】【F:services/tei/Dockerfile†L1-L22】【F:services/reranker/Dockerfile†L1-L22】
- Proxy hardens TLS, mTLS, LAN allow-lists, and per-service reverse proxies with JSON logging.【F:proxy/Caddyfile†L1-L71】
- `locks/VERSIONS.lock` records every digest consumed by `.env.example`, ensuring Compose profiles only run pinned images and aligned model metadata.【F:locks/VERSIONS.lock†L1-L38】【F:.env.example†L18-L64】

## Data, ingestion, and vendor assets
- Postgres schema and row-level security policies define the document/chunk/embed lifecycle and role separation (`shs_app_r`, `shs_app_rw`).【F:db/schema.sql†L1-L112】【F:db/policies.sql†L1-L53】
- n8n bootstrap flows watch the ingest directory, hash new files, and orchestrate document registration, aligning with README pipeline descriptions.【F:n8n/init_flows.json†L1-L18】【F:README.md†L63-L104】
- Vendored models (`vendor/models`) and wheelhouses (`vendor/wheels`) are generated via helper scripts to keep offline builds reproducible.【F:vendor/models/tei/hash_embedding.json†L1-L6】【F:scripts/build_wheelhouse.sh†L1-L28】【F:scripts/fetch_models.sh†L1-L34】

## Automation & observability
- `scripts/status.sh` summarises base URLs, enabled profiles, service roster, TLS fingerprint verification, and optional digest checks for CI drift detection.【F:scripts/status.sh†L118-L160】
- `scripts/backup.sh` and `scripts/restore.sh` encrypt evidence with `age`, copy TLS assets, sync MinIO contents, and replay Postgres dumps, all logged to `logs/shs.jsonl`.【F:scripts/backup.sh†L4-L105】【F:scripts/restore.sh†L4-L119】
- TLS helpers under `scripts/tls/` generate deterministic CA/leaf material and export workstation bundles referenced in the Runbook TLS chapter.【F:RUNBOOK.md†L21-L35】
- Workspace guard ensures Docker-compatible repository names by creating sanitized symlinks, preventing volume errors in dev containers.【F:scripts/validate_workspace.sh†L1-L71】
- `scripts/discover_components.sh` and `scripts/build_lock.py` drive the component discovery → lockfile pipeline used by both the Makefile and `verify.sh`.【F:scripts/discover_components.sh†L4-L55】【F:scripts/build_lock.py†L1-L38】【F:verify.sh†L24-L100】

## Testing & compliance
- Acceptance scripts cover TLS health, ingest idempotency, semantic/vector queries, SQL probes, sync reconciliation, and service resilience; each logs structured JSON with trace IDs.【F:tests/acceptance/01_health.sh†L1-L28】【F:tests/acceptance/06_resilience.sh†L1-L30】
- README and Runbook instruct operators to run `make test` once services are online to capture evidence for audits.【F:README.md†L121-L147】【F:RUNBOOK.md†L36-L57】
- `docs/audit-matrix.md` scores controls such as transport security, determinism, observability, and promotion discipline, pointing to the same artefacts catalogued here.【F:docs/audit-matrix.md†L1-L38】
- Security overview enumerates transport, authentication, lifecycle, observability, and resilience controls, aligning with Compose health checks and acceptance coverage.【F:SECURITY.md†L1-L34】

## Governance & documentation nexus
- The project compendium remains the narrative guide to each house layer, referencing README, audit artefacts, and this map for evidence discovery.【F:docs/project-compendium.md†L1-L47】
- The revision ledger (2025-09-28) tracks outstanding tasks per layer and cross-layer initiatives, ensuring this map stays aligned with planning backlogs.【F:docs/revision-2025-09-28.md†L1-L58】
- Stack pinning integration guide connects external proposals to the maintained automation flow described above.【F:docs/stack-plan-review.md†L1-L74】
- House governance and architecture docs provide design context consumed by the Runbook and security controls catalogue.【F:docs/architecture.md†L1-L40】【F:docs/house-governance.md†L1-L40】
- Audit evidence from professor runs remains archived under `docs/audits/` for future compliance reviews.【F:docs/audits/professor-run1.md†L1-L20】

## Developer experience & CI
- Dev Container setup installs Docker-in-Docker support, ensures sanitized workspace aliases, and runs `make bootstrap` on creation to match local host expectations.【F:.devcontainer/devcontainer.json†L1-L35】
- GitHub Actions workflow enforces shell linting, YAML linting, secret guarding, and digest drift detection by calling `scripts/status.sh --check-digests`.【F:.github/workflows/lint.yml†L1-L69】
- Toolbox wrappers (for example `bin/gcodex`) remain planned but are still referenced in README guidance for operators experimenting with codex overlays.【F:basement/toolbox/README.md†L7-L23】【F:README.md†L148-L170】

## Outdated or superseded artifacts
- `STABILITY_AUDIT.md` and `PRE_RELEASE_AUDIT.md` reflect a pre-consolidation layout (single codex service, missing Compose stack). Refresh them against this map before using their scores or to-do items.【F:STABILITY_AUDIT.md†L9-L45】【F:PRE_RELEASE_AUDIT.md†L9-L40】
- Legacy advice about adding directories or workflows (e.g., `docs/` creation, `make build` suggestions) has been replaced by the current documentation tree and Makefile supply-chain targets described above.【F:PRE_RELEASE_AUDIT.md†L9-L36】【F:Makefile†L95-L166】

## Maintenance checklist
- When adding new services or overlays, update `compose.yaml`, `.env.example`, `locks/VERSIONS.lock`, and the relevant section of this map in the same change set to keep documentation and automation in lockstep.【F:compose.yaml†L1-L244】【F:.env.example†L18-L64】【F:locks/VERSIONS.lock†L1-L38】
- Record host or control changes simultaneously in Fundament docs, RUNBOOK prerequisites, the security overview, and the audit matrix to preserve auditability.【F:fundament/README.md†L1-L12】【F:RUNBOOK.md†L5-L18】【F:SECURITY.md†L1-L34】【F:docs/audit-matrix.md†L1-L38】
- Keep this repository map linked from the README and project compendium so operators and reviewers always land on the latest evidence set.【F:README.md†L42-L68】【F:docs/project-compendium.md†L1-L47】
