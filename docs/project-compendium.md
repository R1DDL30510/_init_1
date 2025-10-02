# SHS Whole-House Compendium & Presentation

> “Secure the house, illuminate the library, promote with confidence.” — SHS mantra

This compendium guides reviewers, operators, and new contributors through the entire Secure Home Systems house. It mirrors the project structure from Fundament through Stable, orients readers with a chapter legend, and signposts deeper documentation such as the pre-release audit, security register, and runbook appendices.

## Legend of Chapters & Topics
| Chapter | Focus | Jump Point |
| --- | --- | --- |
| [0. Orientation](#0-orientation) | Repository atlas, personas, and documentation map. | [`README.md`](../README.md) |
| [1. Fundament](#1-fundament-host-foundations) | Host-level requirements, Docker/Git baselines, promotion notes. | [`fundament/`](../fundament/) |
| [2. Basement](#2-basement-service-toolbox) | Toolbox mono-repo, service stubs, schema sources, Compose drafts. | [`basement/`](../basement/) |
| [3. Wardrobe](#3-wardrobe-overlay-galleria) | Overlay profiles, gcodex wrappers, CI parity surfaces. | [`wardrobe/`](../wardrobe/) |
| [4. Entrance](#4-entrance-canary-control) | Canary gating, telemetry prep, promotion decision flows. | [`entrance/`](../entrance/) |
| [5. Stable](#5-stable-production-ready) | Production rollout skeletons, monitoring plans. | [`stable/`](../stable/) |
| [6. Governance](#6-governance-and-controls) | Security controls, audit mapping, promotion checklists. | [`docs/pre-release-audit.md`](pre-release-audit.md) |
| [7. Library Enablement](#7-library-enable-the-knowledge-base) | Knowledge-base taxonomy, ingestion workflow, stewardship. | [`docs/library-schema.md`](library-schema.md) |
| [Appendix](#appendix-deep-dives--artifacts) | Evidence repositories, diagrams, future briefs. | Multiple |

## 0. Orientation
- **Personas served:** Platform Ops (bootstrap & TLS), SecOps (controls, audits), Documentation Guild (knowledge base), Builders (LLM workflows), Review Board (promotion decisions).
- **Navigation cues:**
  - Start with [`README.md`](../README.md) for the Atlas and change-management roadmap.
  - Use this compendium to understand how documents intersect; inline links point to the canonical source.
  - Follow the [Whole-House governance chapter](#6-governance-and-controls) before promoting beyond Wardrobe.
- **Quick reference map:**
  - **Operational:** [`RUNBOOK.md`](../RUNBOOK.md) → lifecycle commands, rotations, drills.
  - **Security:** [`SECURITY.md`](../SECURITY.md) → threat model and control register.
  - **Compliance:** [`docs/audit-matrix.md`](audit-matrix.md) → scored industry alignment.
  - **Audit readiness:** [`docs/pre-release-audit.md`](pre-release-audit.md) → gating tasks with evidence expectations.

## 1. Fundament (Host Foundations)
- **Responsibilities:** Document host prerequisites (OS, Docker, Git), version alignment, and promotion criteria prior to container stack execution.
- **Key artifacts:**
  - [`fundament/versions.yaml`](../fundament/versions.yaml) — pinned host dependencies.
  - [`docs/architecture.md`](architecture.md#layer-roles) — baseline description of the layer.
  - [`docs/revision-2025-09-28.md`](revision-2025-09-28.md#fundament) — open tasks and owners.
- **Operational guidance:** Review host patch cadence in [`RUNBOOK.md`](../RUNBOOK.md#platform-operations) before altering Docker Engine versions.

## 2. Basement (Service Toolbox)
- **Responsibilities:** Maintain service stubs, manage the toolbox mono-repo (`basement/toolbox/`), and document Compose drafts.
- **Key artifacts:**
  - [`basement/toolbox/projects/toolbox/README.md`](../basement/toolbox/projects/toolbox/README.md) — canonical compose experiments.
  - [`docs/audit-matrix.md`](audit-matrix.md#platform-security) — control scores related to local execution.
  - [`docs/revision-2025-09-28.md`](revision-2025-09-28.md#basement) — backlog of toolbox enhancements.
- **Operational guidance:** Align new scripts with [`scripts/`](../scripts/) and mirror purpose statements in the toolbox README before automation changes.

## 3. Wardrobe (Overlay Galleria)
- **Responsibilities:** Provide CPU/GPU/CI overlays, wrappers (e.g., `gcodex`), and parity tooling between hosts.
- **Key artifacts:**
  - [`wardrobe/`](../wardrobe/) — overlay manifests and wrappers.
  - [`docs/pre-release-audit.md`](pre-release-audit.md#36-house-architecture-governance) — promotion readiness for Wardrobe → Entrance.
  - [`docs/revision-2025-09-28.md`](revision-2025-09-28.md#wardrobe) — overlay roadmap items.
- **Operational guidance:** Ensure overlays inherit TLS and secrets posture from Fundament and Basement before canary promotion.

## 4. Entrance (Canary Control)
- **Responsibilities:** Stage canary rollout plans, telemetry capture, and gating disciplines prior to Stable.
- **Key artifacts:**
  - [`entrance/`](../entrance/) — canary scaffolds and telemetry placeholders.
  - [`docs/pre-release-audit.md`](pre-release-audit.md#5-release-recommendation) — promotion requirements and evidence.
  - [`docs/revision-2025-09-28.md`](revision-2025-09-28.md#entrance) — pending canary automation.
- **Operational guidance:** Reference the [Change Management chapter](#64-promotion-discipline) before approving canary scope expansions.

## 5. Stable (Production Ready)
- **Responsibilities:** Host production-ready manifests, monitoring definitions, and final promotion evidence.
- **Key artifacts:**
  - [`stable/`](../stable/) — production skeletons.
  - [`docs/pre-release-audit.md`](pre-release-audit.md#5-release-recommendation) — Stable gate conditions.
  - [`docs/revision-2025-09-28.md`](revision-2025-09-28.md#stable) — stabilization backlog.
- **Operational guidance:** Confirm quarterly restore drills (GA-05) and decision matrix updates (GA-04) before sign-off.

## 6. Governance and Controls
### 6.1 Control Register
- [`SECURITY.md`](../SECURITY.md) remains the single source of truth for control descriptions, mapped to NIST CSF, ISO/IEC 27001, and CIS Controls.
- [`docs/audit-matrix.md`](audit-matrix.md) provides scoring; update both when controls evolve.

### 6.2 Pre-Release Audit
- [`docs/pre-release-audit.md`](pre-release-audit.md) tracks audit evidence, findings, and gating actions for Wardrobe → Entrance and beyond.
- Cross-links now reference this compendium in Section 6 appendices to keep navigation coherent.

### 6.3 House Governance Blueprint
- Planned [`docs/house-governance.md`](house-governance.md) will host dependency matrices and per-layer promotion checklists (GA-06).
- Until publication, use the [Layer chapters](#1-fundament-host-foundations) and [`docs/architecture.md`](architecture.md) for mapping dependencies.

### 6.4 Promotion Discipline
- [`docs/revision-2025-09-28.md`](revision-2025-09-28.md#promotion-discipline) will receive the Canary → Stable decision matrix (GA-04).
- Ensure all gating actions from Section 4 of the audit are tracked as checklist items with owners.

## 7. Library: Enable the Knowledge Base
- Draft the knowledge-base taxonomy and ingestion workflow in [`docs/library-schema.md`](library-schema.md); current content is a guarded stub. : Bitte durch Operator verifizieren!
- Mirror curator roles and review cadence in [`RUNBOOK.md`](../RUNBOOK.md#knowledge-base-operations) once available.
- Capture dependencies between library assets and service overlays in the future house-governance blueprint.

## Appendix: Deep Dives & Artifacts
- **Evidence Portfolio:** [`docs/audit-matrix.md`](audit-matrix.md) + [`docs/pre-release-audit.md`](pre-release-audit.md#6-appendices) ensure all findings cite canonical files.
- **Diagrams:** [`docs/architecture.md`](architecture.md#mermaid-overview) hosts the mermaid system map; copy to presentations as needed.
- **Revision History:** [`docs/revision-2025-09-28.md`](revision-2025-09-28.md) remains the living backlog; cross-reference gating IDs (GA-01…GA-07).
- **Operational Playbooks:** [`RUNBOOK.md`](../RUNBOOK.md) captures command-level detail; call out acceptance test evidence there when new coverage lands.
- **Future Briefs:** Add emerging topics (e.g., identity provider integration) under new appendix bullets linking to draft docs in `basement/toolbox/documents/`.

---

**How to use this compendium:** skim the legend for the desired layer, follow the jump point, then return via browser history or README links. Keep the compendium updated whenever a new document, directory, or promotion gate is introduced.
