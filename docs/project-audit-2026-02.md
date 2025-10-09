# Secure Home Systems Repository Audit (February 2026)

## 1. Executive Summary
Secure Home Systems (SHS) presents a mature self-hosted RAG stack with strong emphasis on deterministic deployments, offline operation, and operational guardrails. Documentation is exceptionally rich, and container orchestration reflects defensive defaults. The main risks stem from duplicated maintenance logic, limited error handling in helper tooling, and reliance on manual promotion workflows without automated evidence capture.

## 2. Architecture & Infrastructure
- The README gives stakeholders a clear system map, summarising core services, operational profiles, and governance artefacts that bind the stack together.【F:README.md†L5-L138】
- `compose.yaml` enforces least-privilege defaults (custom UID/GID, `cap_drop`, read-only mounts) and comprehensive health probes across all core services, supporting fail-closed behaviour.【F:compose.yaml†L1-L214】
- Make targets guard bootstrap prerequisites, validate TLS assets, and wire status reporting directly into post-start checks, reinforcing reproducible bring-up sequences.【F:Makefile†L14-L86】

## 3. Code Quality & Maintainability
- Shell utilities such as `scripts/status.sh` follow defensive Bash patterns (`set -euo pipefail`, input validation helpers) and surface actionable operational telemetry, demonstrating high scripting discipline.【F:scripts/status.sh†L1-L185】
- The PostgreSQL schema is explicit about hashing, row-level security, and ingestion idempotency, providing a sound data layer foundation for RAG workloads.【F:db/schema.sql†L1-L113】
- `scripts/build_lock.py` has minimal error handling (assumes presence and shape of `tmp/components.csv`) and hard-codes placeholder metadata (`license = "unknown"`), reducing resilience of supply-chain tooling.【F:scripts/build_lock.py†L1-L42】
- The Makefile repeats the supply-chain helper targets verbatim, which increases the risk of configuration drift and complicates future edits.【F:Makefile†L95-L200】

## 4. Documentation & Knowledge Management
- Governance, security, and operational expectations are centralised in dedicated documents (`SECURITY.md`, `RUNBOOK.md`, audit matrix), producing a coherent body of knowledge that supports audits and onboarding.【F:SECURITY.md†L1-L39】【F:docs/audit-matrix.md†L1-L42】
- Cross-references in the README tie each repository area to source documents, ensuring navigation remains discoverable as the project grows.【F:README.md†L29-L58】
- The documentation set is intentionally redundant (e.g., architecture vs. revision roadmap) with a stated plan to consolidate, but no tracked deadline, leaving room for documentation drift.【F:README.md†L128-L133】

## 5. Testing & Automation
- Acceptance scripts exercise TLS-gated ingress, ingestion, SQL queries, and resilience, and the Makefile automates sequential execution once the stack is running.【F:tests/acceptance/01_health.sh†L1-L28】【F:Makefile†L36-L52】
- GitHub Actions lint shell/YAML, guard secrets, and verify image digests, offering strong static assurance for infrastructure artefacts.【F:.github/workflows/lint.yml†L1-L54】
- There are no lightweight unit or integration tests for helper scripts or SQL routines, so regressions outside the full stack may go unnoticed until late in the promotion pipeline (also noted in docs as pending work).【F:docs/audit-matrix.md†L1-L42】

## 6. Security & Compliance
- The security overview details threat modelling, control catalogues, and maintenance expectations, aligning with the compliance scoring documented in the audit matrix.【F:SECURITY.md†L1-L39】
- Row-level security and role separation in the database enforce least privilege for application actors out of the box.【F:db/schema.sql†L4-L47】
- TLS automation and fingerprint verification paths exist, but only the status script checks digests; automated certificate expiry monitoring is flagged as a future enhancement in the matrix.【F:scripts/status.sh†L102-L185】【F:docs/audit-matrix.md†L1-L42】

## 7. Key Risks & Recommendations
| Area | Observation | Impact | Recommendation |
| --- | --- | --- | --- |
| Supply-chain tooling | `scripts/build_lock.py` fails if `tmp/components.csv` is absent/corrupt and stamps `license = "unknown"` for every entry. | Broken automation or incomplete compliance evidence during vendor updates. | Add argument parsing with explicit error messages, validate required columns, and propagate licence metadata from the CSV source.【F:scripts/build_lock.py†L6-L34】 |
| Build orchestration | Supply-chain Make targets are duplicated, inviting divergence between definitions. | Maintenance overhead and inconsistent CI outcomes. | Collapse duplicated blocks into single target definitions and add regression coverage in CI to detect accidental edits.【F:Makefile†L95-L200】 |
| Testing scope | Automated checks focus on linting and full acceptance runs; helper scripts and SQL lack targeted tests. | Defects in provisioning scripts or PL/pgSQL functions may escape detection until manual testing. | Introduce unit tests (e.g., pytest + shellspec) for scripts and use `pg_prove` or similar to validate database functions offline.【F:Makefile†L36-L52】【F:db/schema.sql†L49-L113】 |
| Documentation governance | Planned consolidation of architecture/revision docs lacks a tracked milestone. | Potential drift between authoritative sources during long-term maintenance. | Record an explicit deadline/responsible owner in revision logs or the audit matrix to ensure follow-through.【F:README.md†L128-L133】【F:docs/audit-matrix.md†L1-L42】 |
| Licensing clarity | Repository lacks an explicit licence file, complicating reuse/distribution assurances. | Legal uncertainty for adopters and partners. | Introduce a top-level `LICENSE` that reflects intended usage (e.g., AGPL, Apache 2.0) and reference it in the README. |

## 8. Suggested Next Steps
1. Refactor supply-chain tooling (Makefile + lock builder) and backfill automated tests to prevent regressions before the next quarterly maintenance cycle.【F:Makefile†L95-L200】【F:scripts/build_lock.py†L1-L42】
2. Define a documentation consolidation milestone in the revision log and update the audit matrix once completed.【F:README.md†L128-L133】【F:docs/audit-matrix.md†L1-L42】
3. Add a repository licence and update onboarding docs to clarify contribution and deployment terms.
4. Extend CI to lint PL/pgSQL and execute shell/unit tests to catch issues earlier in the pipeline.【F:db/schema.sql†L49-L113】【F:.github/workflows/lint.yml†L1-L54】
