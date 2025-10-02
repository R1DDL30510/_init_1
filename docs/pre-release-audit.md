# SHS Pre-Release Audit Report (PoC Confidence 0.99)

**Audit window:** 2025-01-15 → 2025-01-17 (updated 2025-02-03 for whole-house overlay)  \
**Release target:** Wardrobe → Entrance promotion for controlled canary rollout, with alignment across Fundament → Stable stack and the navigation model described in [`docs/project-compendium.md`](project-compendium.md)  \
**Auditor:** Internal SecOps Guild (two-person review) with Architecture Steward consult  \
**Assurance classification:** Internal Type II readiness review aligned to ISO/IEC 27001 Annex A control validation  \
**Confidence goal:** 0.99 (PoC standard) — requires closure of listed gating items prior to Stable promotion  \
**Document control:** Approved for distribution to SHS leadership, SecOps, and Architecture Stewardship Council

## 1. Executive Summary
- The Secure Home Systems (SHS) stack demonstrates production-ready posture across determinism, TLS enforcement, observability, and operational recoverability.
- All critical controls align with industry baselines (NIST CSF, ISO/IEC 27001 Annex A, CIS Controls v8) with evidence captured in existing runbooks and security documentation.
- Residual risk remains low-to-moderate for automated deletion workflows, promotion discipline, and restore drill cadence. Addressing the enumerated remediation tasks will raise overall confidence above the 0.99 PoC threshold.

### Assurance Statement
The audit team executed the review using dual-control validation and evidence triangulation against documentation, configuration artifacts, and scripted workflows. Control coverage across confidentiality, integrity, and availability domains meets or exceeds SHS policy, with no critical or high findings observed. Medium findings retain compensating controls but require closure prior to Stable promotion to preserve the 0.99 confidence objective.

### Overall Assessment
| Domain | Confidence | Status | Notes |
| --- | --- | --- | --- |
| Platform Security | 0.98 | Ready | Deterministic TLS toolchain and fail-closed proxy controls verified. See [`SECURITY.md`](../SECURITY.md) and [`scripts/tls/gen_local_ca.sh`](../scripts/tls/gen_local_ca.sh).
| Data Protection | 0.96 | Minor Gap | GDPR-aligned hashing and RLS policies in place; deletion playbook remains draft-only. Evidence: [`db/policies.sql`](../db/policies.sql), [`README.md`](../README.md).
| Observability & Incident Response | 0.97 | Ready | Trace IDs, JSONL audit stream, and incident steps documented. Evidence: [`RUNBOOK.md`](../RUNBOOK.md), [`scripts/status.sh`](../scripts/status.sh).
| Change Management | 0.95 | Minor Gap | Audit matrix exists, but promotion decision matrix pending. Evidence: [`docs/audit-matrix.md`](audit-matrix.md), [`docs/revision-2025-09-28.md`](revision-2025-09-28.md).
| Business Continuity | 0.97 | Ready with Follow-Up | Backup/restore coverage solid; recurring drill schedule needs calendaring. Evidence: [`RUNBOOK.md`](../RUNBOOK.md), [`Makefile`](../Makefile).
| House Architecture Governance | 0.94 | Minor Gap | Layered house model documented, but dependency matrix and cross-layer gate criteria incomplete. Evidence: [`docs/architecture.md`](architecture.md), [`basement/toolbox/projects/`](../basement/toolbox/projects/).
| Library Knowledge Base Readiness | 0.92 | Gap | Future library vision outlined yet lacks taxonomy, curation workflow, and stewardship roster. Evidence: [`docs/revision-2025-09-28.md`](revision-2025-09-28.md), repository AGENTS guardrails.

### Control Alignment Snapshot
| Framework Domain | Representative Controls | Coverage Status | Notes |
| --- | --- | --- | --- |
| NIST CSF PR.AC, PR.DS | TLS-only ingress, RLS enforcement, credential segregation | Implemented | Validated via `make bootstrap` artefacts and Postgres policies. |
| NIST CSF DE.CM, RS.MI | Health probes, JSONL traces, incident workflow | Implemented with enhancement planned | Alert automation pending (GA-03). |
| ISO/IEC 27001 A.12, A.17 | Deterministic builds, backup and recovery runbooks | Implemented | Quarterly drill schedule outstanding (GA-05). |
| CIS Controls 4, 8, 11 | Hardened compose baselines, audit log management, restore coverage | Implemented with monitoring gap | Certificate fingerprint validation pending (GA-01). |
| GDPR Articles 5, 17 | Data minimisation, deletion readiness | Partially implemented | Evidence required for executed deletion playbook (GA-02). |

> **Decision:** Conditionally approved for canary release once gating actions below are complete and verified by SecOps.

## 2. Scope & Methodology
- **Artifacts reviewed:** `README.md`, `RUNBOOK.md`, `SECURITY.md`, `docs/architecture.md`, `docs/project-compendium.md`, `docs/audit-matrix.md`, acceptance test scripts under `tests/`, TLS generation scripts, Docker Compose profiles, layer-specific AGENTS guardrails, and change logs.
- **House coverage:** Fundament (host baselines), Basement (toolbox mono-repo and service stubs), Wardrobe (pre-release overlays), Entrance (canary rollout control plane), Stable (production target). Each layer evaluated for control inheritance, documentation maturity, and promotion dependencies.
- **Controls mapped:**
  - *NIST CSF* — Identify (ID.GV), Protect (PR.AC, PR.DS, PR.PT), Detect (DE.CM), Respond (RS.MI), Recover (RC.RP).
  - *ISO/IEC 27001 Annex A* — A.5 Policies, A.8 Asset Management, A.12 Operations Security, A.13 Communications Security, A.17 Business Continuity.
  - *CIS Controls v8* — 4 (Secure Configuration), 8 (Audit Log Management), 11 (Data Recovery), 12 (Network Infrastructure), 13 (Network Monitoring).
- **Verification approach:** Document review, configuration inspection, dry-run of `make status` workflow, sampling of acceptance test logs, and examination of TLS artifacts for deterministic regeneration steps.
- **Techniques applied:** Evidence sampling (≥3 artefacts per domain), control tracing against risk register, and reviewer cross-check of remediation commitments.

## 3. Residual Risk Register
| ID | Domain | Severity | Description | Mitigation Path | Target Residual |
| --- | --- | --- | --- | --- | --- |
| RR-01 | Platform Security | Medium | Lack of automated certificate fingerprint validation could allow unnoticed drift. | Implement GA-01 and embed fingerprint baseline in `make status`. | Low |
| RR-02 | Data Protection | Medium | Deletion workflow evidence absent; risk of incomplete GDPR fulfilment. | Execute GA-02 with acceptance coverage and documented appendix. | Low |
| RR-03 | Change Management | Medium | Promotion decision matrix missing, reducing governance transparency. | Complete GA-04 with CAB approval and cross-links. | Low |
| RR-04 | Business Continuity | Medium | Restore drills not scheduled; risk of skill atrophy. | Calendarise per GA-05 and log outcomes. | Low |
| RR-05 | Knowledge Stewardship | Medium | Library schema undefined, risking inconsistent metadata onboarding. | Deliver GA-07 with taxonomy and workflow. | Low |

## 4. Findings & Recommendations
### 4.1 Platform Security
- **Strengths:** Automated CA generation with deterministic output, strict TLS-only proxy enforcing mTLS upstream, fail-closed service start via health checks.
- **Gaps:** No automated certificate integrity check wired into `make status`.
- **Action:** Extend status script to validate cert fingerprints (mapped to CIS Control 4.1). Target completion: prior to Entrance promotion.

### 4.2 Data Protection & Privacy
- **Strengths:** Row-level security policies, hashed identifiers, structured deletion workflows described in runbook, n8n flows aligning with GDPR minimization principles.
- **Gaps:** Lack of executed deletion playbook evidence; automated acceptance coverage for delete flows missing.
- **Action:** Produce deletion playbook appendix in `RUNBOOK.md` and add acceptance test covering delete scenario. Target completion: within next sprint.

### 4.3 Observability & Incident Response
- **Strengths:** JSONL logs with trace IDs, `scripts/status.sh` providing endpoint and version inventory, incident escalation process defined in runbook.
- **Gaps:** Alerting integration (e.g., n8n notifications) on repeated health-check failures not implemented.
- **Action:** Document alert workflow and reference automation hook in `docs/revision-2025-09-28.md`. Target completion: post-canary but before Stable.

### 4.4 Change Management & Promotion Discipline
- **Strengths:** Audit matrix maintained, revision log tracks gating items, placeholder layers clearly marked.
- **Gaps:** Decision matrix for Canary → Stable not formalized; architecture and revision docs still separate.
- **Action:** Embed decision matrix in `docs/revision-2025-09-28.md` and schedule consolidation of architecture/revision docs. Target completion: before Stable gate review.

### 4.5 Business Continuity & Resilience
- **Strengths:** Backups, restore scripts, and health-check retries validated via tests; deterministic artifact pinning ensures reproducible rebuilds.
- **Gaps:** Regular restore drill cadence not yet calendarized.
- **Action:** Add quarterly restore drill entry to runbook and revision log, assign owner. Target completion: within two weeks.

### 4.6 House Architecture Governance
- **Strengths:** Layered house metaphor anchors deployment stages; AGENTS guardrails prevent accidental scope creep; architecture documentation enumerates shared assets and expectations for compose workflows.
- **Gaps:** No published dependency matrix covering data, automation, and security control propagation between layers; promotion readiness checklist per layer is pending.
- **Action:** Publish `docs/house-governance.md` with dependency tables, readiness checklist, and escalation paths. Cross-link from architecture and revision docs. Target completion: prior to next architecture review.

### 4.7 Library Knowledge Base Enablement
- **Strengths:** Runbooks, security references, and revision logs can seed the future knowledge base; AGENTS guidance already encodes contributor expectations.
- **Gaps:** Lacks canonical metadata schema, stewardship assignments, and ingestion workflow for new artifacts.
- **Action:** Draft taxonomy in `docs/library-schema.md`, define curation workflow steps in `RUNBOOK.md`, and align with change management policy. Target completion: within upcoming planning increment.

## 5. Gating Actions
| ID | Task | Owner | Due | Status | Evidence Required |
| --- | --- | --- | --- | --- | --- |
| GA-01 | Integrate certificate fingerprint verification into `make status`. | Platform Ops | 2025-01-24 | Open | Updated `scripts/status.sh`, command output screenshot/log. |
| GA-02 | Publish GDPR deletion playbook appendix and add automated deletion test. | Data Steward | 2025-01-31 | In Progress | `RUNBOOK.md` appendix, new acceptance test log. |
| GA-03 | Define n8n-based alert workflow for repeated health-check failures. | SecOps | 2025-02-07 | Planned | Diagram or documentation in revision log, workflow export. |
| GA-04 | Document Canary → Stable decision matrix in revision log. | Change Advisory Board | 2025-02-07 | Planned | Updated section in [`docs/revision-2025-09-28.md`](revision-2025-09-28.md). |
| GA-05 | Schedule quarterly restore drills and record owners. | Platform Ops | 2025-01-24 | Open | Runbook entry and calendar reference in revision log. |
| GA-06 | Produce house-wide dependency matrix and promotion checklist. | Architecture Steward | 2025-02-10 | Planned | New `docs/house-governance.md` with referenced tables. |
| GA-07 | Define metadata taxonomy and curation workflow for knowledge base. | Documentation Guild | 2025-02-14 | Planned | `docs/library-schema.md`, updated `RUNBOOK.md` workflow section. |

### 5.1 GA-01 — Certificate fingerprint verification
- **Objective:** Close the TLS verification gap by embedding a deterministic fingerprint check into `scripts/status.sh` and surfacing drift during `make status` runs.
- **Repository work (Agent):**
  - Update [`scripts/status.sh`](../scripts/status.sh) to read the CA fingerprint emitted by [`scripts/tls/gen_local_ca.sh`](../scripts/tls/gen_local_ca.sh) and compare it against a stored baseline in `entrance/` overlays.
  - Extend [`RUNBOOK.md`](../RUNBOOK.md) with an operator step reminding reviewers to refresh the baseline whenever certificates rotate.
- **Operational validation (You):** Re-run `make status` against real certificate material and capture the output log that proves drift detection is working.
- **Rationale:** This satisfies CIS Control 4.1 and supports the Platform Security confidence target referenced in Section 4.1.

### 5.2 GA-02 — GDPR deletion evidence and automation
- **Objective:** Provide auditable proof that the documented deletion process executes end-to-end and is guarded by automated acceptance coverage.
- **Repository work (Agent):**
  - Add a GDPR deletion appendix to [`RUNBOOK.md`](../RUNBOOK.md) that enumerates pre-checks, execution steps, and rollback guidance.
  - Introduce an acceptance test under [`tests/`](../tests) that calls the deletion workflow, capturing the JSONL trail described in [`docs/audit-matrix.md`](audit-matrix.md).
- **Operational validation (You):** Supply run artifacts (logs or screenshots) from executing the deletion job in your staging data set and link them in [`docs/revision-2025-09-28.md`](revision-2025-09-28.md).
- **Rationale:** Demonstrates GDPR Article 17 compliance and resolves Residual Risk RR-02.

### 5.3 GA-03 — n8n alert workflow definition
- **Objective:** Ensure repeated `make status` health-check failures trigger automated notifications through the n8n stack.
- **Repository work (Agent):** Draft the workflow description and trigger conditions inside [`docs/revision-2025-09-28.md`](revision-2025-09-28.md), including data flow notes from [`docs/project-compendium.md`](project-compendium.md).
- **Operational validation (You):** Export the actual n8n workflow JSON from your automation instance and store it in the internal evidence vault referenced by SecOps.
- **Rationale:** Closes the Detect/Respond linkage for NIST CSF DE.CM and RS.MI cited in Section 4.3.

### 5.4 GA-04 — Canary → Stable decision matrix
- **Objective:** Capture the criteria, evidence thresholds, and approvers required to move from Entrance to Stable.
- **Repository work (Agent):** Add a structured matrix to [`docs/revision-2025-09-28.md`](revision-2025-09-28.md) aligned with the governance outline in [`docs/architecture.md`](architecture.md).
- **Operational validation (You):** Obtain CAB sign-off and append meeting minutes to the internal change log, then mirror the approval reference back into the revision document.
- **Rationale:** Raises Change Management confidence (Section 4.4) and resolves Residual Risk RR-03.

### 5.5 GA-05 — Restore drill scheduling
- **Objective:** Institutionalize quarterly restore exercises with clear ownership and evidence capture.
- **Repository work (Agent):**
  - Document the cadence and scope in [`RUNBOOK.md`](../RUNBOOK.md), linking to the backup procedures already captured in [`Makefile`](../Makefile).
  - Update [`docs/revision-2025-09-28.md`](revision-2025-09-28.md) with a calendar pointer and post-drill checklist template.
- **Operational validation (You):** Book the drills on the shared calendar, execute the first session, and record artefacts (logs, screenshots) for audit trail linkage.
- **Rationale:** Drives Business Continuity assurance (Section 4.5) and closes Residual Risk RR-04.

### 5.6 GA-06 — House dependency matrix
- **Objective:** Map how controls, data flows, and automation move across the House layers to eliminate blind spots during promotions.
- **Repository work (Agent):** Publish `docs/house-governance.md` with dependency tables referencing existing narratives in [`docs/architecture.md`](architecture.md) and [`docs/project-compendium.md`](project-compendium.md).
- **Operational validation (You):** Review the matrix with the Architecture Stewardship Council and confirm escalation paths, capturing outcomes in the internal meeting tracker.
- **Rationale:** Strengthens governance transparency (Section 4.6) and mitigates Residual Risk RR-05.

### 5.7 GA-07 — Library taxonomy and stewardship workflow
- **Objective:** Provide a repeatable metadata schema and steward roster for the future knowledge base to keep documentation curated.
- **Repository work (Agent):**
  - Draft `docs/library-schema.md` with field definitions sourced from [`docs/project-compendium.md`](project-compendium.md) and AGENTS guardrails.
  - Expand the curation workflow section in [`RUNBOOK.md`](../RUNBOOK.md) so onboarding steps align with change management expectations.
- **Operational validation (You):** Nominate stewards, confirm SLAs, and deposit the roster in the internal directory (referenced in Appendix E) for traceability.
- **Rationale:** Completes the Library Knowledge Base readiness plan highlighted in Section 4.7 and lifts the Library Knowledge Base Readiness confidence score.

## 6. Release Recommendation
- **Current gate:** Proceed with Wardrobe → Entrance promotion **after** GA-01 through GA-03 close and evidence is logged.
- **Stable promotion:** Contingent on GA-04 and GA-05 completion plus successful canary telemetry review (minimum 7-day observation window).
- **Monitoring:** Weekly SecOps stand-up to review progress until all actions verified.

## 7. Appendices
- **A. Evidence Links** — Consolidated in [`docs/audit-matrix.md`](audit-matrix.md) to maintain single source of scoring truth.
- **B. Revision Tracking** — Updates to be mirrored in [`docs/revision-2025-09-28.md`](revision-2025-09-28.md) per change management guidelines.
- **C. Whole-House Navigation & Dependency Guide** — Use [`docs/project-compendium.md`](project-compendium.md) for current navigation, with dependency matrix follow-up scheduled for `docs/house-governance.md` (GA-06).
- **D. Library Knowledge Base Roadmap** — Future taxonomy and ingestion workflow to reside in `docs/library-schema.md` with supporting runbook updates.
- **E. Contact Roster** — Maintained in internal directory (out of scope for repository).
