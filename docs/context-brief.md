# SHS Bootstrap Stack – Consolidated Context Brief

## Project Snapshot
- **Mission:** Deliver an offline, TLS-enforced RAG stack that answers questions from local knowledge sources through Docker-based services.
- **Core Services:** Proxy, OpenWebUI, n8n, Postgres+pgvector, MinIO, OCR/TEI, reranker, optional Ollama GPU profile; all pinned via `VERSIONS.lock` and orchestrated with `make` helpers.
- **Security Posture:** Emphasizes least privilege, immutable versioning, encrypted backups with `age`, and comprehensive audit evidence across `SECURITY.md`, `docs/audit-matrix.md`, and `docs/pre-release-audit.md`.

## Layered House Model & Status
1. **Fundament (Host Foundations)**
   - Maintains host prerequisites, Docker/Git versions (`fundament/versions.yaml`), and promotion checks (`fundament/STATE_VERIFICATION.md`).
   - Next actions: mirror Docker/Git updates, document host Ollama availability, finalize network/volume templates.
2. **Basement (Service Toolbox)**
   - Houses toolbox mono-repo and service stubs (e.g., Codex/Ollama drafts) without production images.
   - Next actions: harden Codex image, define MCP gateway spec, sync Wardrobe requirements into Compose draft.
3. **Wardrobe (Overlay Galleria)**
   - Prepares cross-platform overlays (`configs/`, `overlays/`, `wrappers/`) for CPU/GPU/CI parity.
   - Next actions: build overlay matrices (driver paths, volumes), outline automation, align with Basement Compose.
4. **Entrance (Canary Control)**
   - Stages canary rollout and telemetry scaffolding.
   - Next actions: draft data flow definitions, canary playbooks, metrics collection once Wardrobe overlays are validated.
5. **Stable (Production Ready)**
   - Keeps production skeletons and monitoring placeholders.
   - Next actions: import promotion gates, plan observability roadmap post-canary success.

## Governance & Documentation Spine
- `README.md` supplies repository atlas, onboarding, and operations quickstart.
- `docs/project-compendium.md` maps personas, layer responsibilities, and navigation cues.
- `RUNBOOK.md` centralizes operational procedures; `SECURITY.md` is the control register.
- `docs/architecture.md` hosts the mermaid overview; `docs/house-governance.md` captures decision matrices.

## Active Cross-Layer Initiatives
1. **Codex ↔ Ollama Verification:** Prepare smoke tests for host-based Ollama; reflect status in audit matrix (Local Execution).
2. **Wardrobe Overlay Matrix:** Document platform deltas and shared workspace strategy; update README consolidation plan.
3. **Promotion Gate Blueprint:** Map `STATE_VERIFICATION.md` checkpoints to layers and encode decision logic (Promotion Discipline).
4. **Toolbox Documentation Hygiene:** De-duplicate Compose drafts, prioritize pending tasks, capture MCP gateway dependencies.
5. **Telemetry Preparation:** Extend Entrance with event flow plans, link Security references when data paths solidify.

## Operational Playbook Highlights
- Workspace validation via `scripts/validate_workspace.sh`; bootstrap with `make bootstrap`, start with `make up`, inspect via `make status`.
- TLS lifecycle handled by `scripts/tls/` (local CA, rotations); secrets isolated in `secrets/` and `.env.local`.
- Data model in `db/schema.sql` and policies in `db/policies.sql`; automation flows seeded in `n8n/init_flows.json`.
- Tests under `tests/acceptance/` confirm encryption, imports, RAG responses, DB queries, sync, and failure handling.

## Promotion & Audit Outlook
- Audit cadence tracked quarterly; promotion readiness gated by `docs/pre-release-audit.md` and cross-referenced evidence.
- Wardrobe → Entrance → Stable path requires satisfying governance checklists, telemetry readiness, and observability commitments.
- Pending publication of `docs/house-governance.md` will formalize dependency matrices; interim references rely on architecture and layer documents.
