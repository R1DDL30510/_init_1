# Secure Home Systems Repository Audit (February 2026)

## 1. Scope & Methodology
This audit covers the full `_init_1` repository with focus on infrastructure-as-code, service configuration, operational scripts, database schema, acceptance tests, and documentation. Evidence was gathered from Docker Compose definitions, shell tooling, CI workflows, database SQL, n8n automation flows, and governance documents (README, runbooks, security notes, audit matrices). Key artefacts were reviewed in situ to confirm traceability and cross-document consistency.【F:compose.yaml†L1-L214】【F:scripts/status.sh†L1-L120】【F:db/schema.sql†L1-L86】【F:n8n/init_flows.json†L1-L70】【F:README.md†L5-L138】【F:RUNBOOK.md†L1-L142】【F:SECURITY.md†L1-L39】【F:docs/audit-matrix.md†L1-L42】

## 2. Executive Summary
Secure Home Systems (SHS) exhibits a robust, defence-in-depth architecture oriented around deterministic, offline-friendly operations. Documentation is comprehensive and cross-referenced, automation embraces least privilege defaults, and acceptance tests target end-to-end behaviour. The primary gaps involve duplicated supply-chain automation, limited automated coverage for helper tooling and SQL, absent repository-level licensing guidance, and insufficient certificate expiry monitoring. Addressing these items will raise maintainability and compliance readiness before the next promotion cycle.

## 3. Architecture & Infrastructure Readiness
- `compose.yaml` enforces restrictive container profiles (custom UID/GID, dropped capabilities, read-only mounts, tight health checks) and funnels all ingress through a mutual-TLS proxy with hardened headers, enabling fail-closed defaults.【F:compose.yaml†L1-L214】【F:proxy/Caddyfile†L1-L56】
- Service-specific configuration locks down OpenWebUI authentication, telemetry, and API access paths to the internal proxy, sustaining the offline-first trust model.【F:services/openwebui/config.yaml†L1-L16】
- Make targets orchestrate bootstrap, certificate rotation, backups, and acceptance tests with workspace validation, ensuring reproducible bring-up and deterministic artefacts.【F:Makefile†L1-L80】【F:Makefile†L36-L52】

## 4. Code Quality & Maintainability
- Shell utilities (e.g., `scripts/status.sh`) use strict Bash flags, structured logging, fingerprint validation, and argument parsing, demonstrating disciplined scripting practices suitable for audited environments.【F:scripts/status.sh†L1-L120】
- The PostgreSQL schema implements row-level security, ingestion idempotency, and typed embeddings, providing a resilient data foundation for RAG workloads.【F:db/schema.sql†L1-L113】
- The n8n bootstrap flow codifies hashing, object storage, OCR, embedding, and Postgres persistence, evidencing a coherent ingestion pipeline with trace propagation.【F:n8n/init_flows.json†L1-L70】
- `scripts/build_lock.py` assumes the presence of `tmp/components.csv`, lacks parameter validation, and populates placeholder licence metadata, reducing the robustness of supply-chain evidence.【F:scripts/build_lock.py†L1-L42】
- Supply-chain targets in the Makefile are duplicated wholesale, which raises drift risk and complicates updates or CI reuse.【F:Makefile†L86-L140】

## 5. Documentation & Knowledge Management
- The README, runbook, security overview, and audit matrix form a cohesive documentation spine that links operational actions with compliance scoring and governance responsibilities.【F:README.md†L5-L138】【F:RUNBOOK.md†L1-L142】【F:SECURITY.md†L1-L39】【F:docs/audit-matrix.md†L1-L42】
- Documentation intentionally duplicates some architectural context across `docs/architecture.md` and `docs/revision-2025-09-28.md`; consolidation is planned but undated, leaving room for drift as changes accumulate.【F:README.md†L128-L133】
- Repository-level licensing terms are absent, leaving stakeholders without clarity on redistribution and contribution expectations.

## 6. Testing, Automation & Tooling
- `make test` executes a trace-aware acceptance suite that validates TLS-gated ingress, ingestion, semantic retrieval, SQL correctness, sync reconciliation, and resilience retries, offering thorough end-to-end assurance once services are online.【F:Makefile†L36-L52】【F:tests/acceptance/01_health.sh†L1-L28】
- GitHub Actions lint shell scripts, YAML manifests, guard against committed secrets, and verify container digest drift, covering critical infrastructure artefacts in CI.【F:.github/workflows/lint.yml†L1-L54】
- There is no lightweight automated testing for helper scripts, SQL routines, or n8n flows; regressions in these areas would surface only after full stack deployment. Extending CI with targeted unit and integration tests remains an open task noted in governance docs.【F:docs/audit-matrix.md†L1-L42】【F:db/schema.sql†L49-L113】

## 7. Security & Compliance Posture
- The security overview outlines threat actors, trust boundaries, control catalogues, and maintenance expectations that align tightly with the audit matrix scoring, enabling transparent compliance tracking.【F:SECURITY.md†L1-L39】【F:docs/audit-matrix.md†L1-L42】
- Mutual TLS, LAN allow-lists, strict security headers, and logging with propagated trace IDs are enforced at the proxy layer, reinforcing zero-trust assumptions inside the Compose overlay network.【F:proxy/Caddyfile†L1-L56】
- Database roles (`shs_app_r`, `shs_app_rw`) and row-level security policies embed least-privilege defaults directly in the schema, reducing the chance of accidental data exposure.【F:db/schema.sql†L4-L47】
- Certificate lifecycle management is deterministic and scriptable, but automated expiry monitoring and alerting remain to be implemented (flagged in the audit matrix).【F:scripts/status.sh†L82-L185】【F:docs/audit-matrix.md†L1-L42】

## 8. Operational Practices & Observability
- The runbook provides detailed bootstrap, TLS, lifecycle, backup/restore, and incident response procedures, aligning operator actions with the automation targets defined in the Makefile.【F:RUNBOOK.md†L1-L183】【F:Makefile†L1-L80】
- Status reporting surfaces fingerprints, health endpoints, version locks, and feature flags, supporting traceable operations and evidentiary logging.【F:scripts/status.sh†L60-L185】
- Logs, digests, and backup artefacts are explicitly catalogued, but periodic restore drills and documentation consolidation require scheduling to maintain audit readiness.【F:docs/audit-matrix.md†L1-L42】

## 9. Risks & Recommendations
| Area | Observation | Impact | Recommendation |
| --- | --- | --- | --- |
| Supply-chain automation | `scripts/build_lock.py` lacks argument validation and stamps `license = "unknown"`, while Makefile targets duplicate helper logic. | Broken evidence generation or inconsistent locks during vendor updates. | Harden `build_lock.py` with CLI args, schema validation, and propagated licence metadata; refactor Makefile targets to reuse shared recipes and add regression coverage in CI.【F:scripts/build_lock.py†L1-L42】【F:Makefile†L86-L140】 |
| Test coverage breadth | No unit/contract tests exist for helper scripts, SQL routines, or n8n flows. | Defects in ingestion, database logic, or scripting may ship undetected until full stack testing. | Introduce shell/unit tests (e.g., shfmt + shellspec, pytest) and SQL validation (`pg_prove` or psql harness) wired into CI to catch regressions earlier.【F:docs/audit-matrix.md†L1-L42】【F:db/schema.sql†L49-L113】 |
| Documentation governance | Architecture vs. revision roadmap remains duplicated without a tracked deadline; no repository licence published. | Risk of stale instructions and unclear legal posture for adopters. | Set a consolidation milestone in `docs/revision-2025-09-28.md` or the audit matrix, and add a top-level `LICENSE` referenced in the README to clarify usage terms.【F:README.md†L128-L133】【F:docs/audit-matrix.md†L1-L42】 |
| Certificate monitoring | Status script validates fingerprints on demand, but automated expiry alerts are absent. | Potential for unnoticed certificate expiry impacting availability. | Extend `scripts/status.sh` or CI to check certificate expiry windows and surface alerts in logs or monitoring workflows.【F:scripts/status.sh†L82-L185】 |

## 11. Readiness Scorecard
| Capability | Evidence Highlights | Readiness |
| --- | --- | --- |
| Architecture & Infrastructure | Hardened Compose profiles, strict proxy defaults, and deterministic make targets. | 88% |
| Code Quality & Automation | Strong scripting standards and end-to-end tests, but helper tooling lacks automated coverage. | 76% |
| Security & Compliance | Defence-in-depth controls and RLS enforcement, awaiting proactive certificate expiry alerts and licence definition. | 74% |
| Documentation & Governance | Cohesive runbook and audit matrix, yet architecture roadmap consolidation remains open. | 80% |
| Overall Release Readiness | Core services demonstrably reliable; remaining gaps are procedural and automation-oriented. | 79% |

## 10. Suggested Next Steps
1. Prioritize the supply-chain tooling refactor and corresponding CI coverage before the next quarterly review to protect deterministic builds.【F:scripts/build_lock.py†L1-L42】【F:Makefile†L86-L140】
2. Define and document the architecture/revision consolidation milestone, updating the audit matrix once completed to maintain documentation integrity.【F:README.md†L128-L133】【F:docs/audit-matrix.md†L1-L42】
3. Establish baseline unit and SQL tests for critical helpers (status, lock builder, ingestion function) and wire them into the existing lint workflow for continuous assurance.【F:.github/workflows/lint.yml†L1-L54】【F:db/schema.sql†L49-L113】
4. Publish a repository licence and align onboarding documentation (README, RUNBOOK) with the chosen terms to eliminate legal ambiguity.【F:README.md†L5-L138】【F:RUNBOOK.md†L1-L142】
5. Implement automated certificate expiry checks (e.g., via `status.sh --check-expiry` or n8n alerts) and document the cadence in the runbook and audit matrix.【F:scripts/status.sh†L82-L185】【F:docs/audit-matrix.md†L1-L42】
