# Stack Pinning Integration Guide

This guide consolidates the earlier review of the external "Image-Pinning & Stabiler Stack" proposal with the
current Secure Home Systems (SHS) repository. It explains where the SHS house already fulfills the proposal,
what differs by design, and how to channel useful ideas into the maintained toolchain and documentation map.

## Executive Summary
- The production bootstrap stack already runs the proxy, OpenWebUI, n8n, database, object storage, OCR, TEI,
  reranker, and GPU-enabled Ollama with health probes and hardened profiles managed from a single
  `compose.yaml` root.【F:compose.yaml†L1-L244】
- Digests are the canonical identifiers for every service today via the YAML lockfile and mirrored
  environment template; both documents are consumed by Compose and the Makefile without tag indirection.
  【F:locks/VERSIONS.lock†L1-L43】【F:.env.example†L1-L64】
- Supply-chain automation already covers lockfile generation, SBOM collection, and vulnerability scans using
  maintained scripts and Make targets, so any enhancement should extend these entry points rather than
  introduce parallel workflows.【F:Makefile†L95-L166】【F:scripts/build_lock.py†L1-L42】【F:scripts/sbom_generate.sh†L1-L29】【F:scripts/audit.sh†L1-L34】

## How this document fits into the SHS house
- `README.md` remains the newcomer atlas that explains the house metaphor, service roster, and the existing
  orientation aids for promotion and security baselines.【F:README.md†L5-L135】
- `docs/project-compendium.md` maps each floor of the house to its canonical artifacts; this guide nests under
  the Basement responsibilities where Compose drafts and tooling live.【F:docs/project-compendium.md†L5-L47】
- The guidance below focuses on keeping the Basement and Wardrobe layers coherent so that overlays and future
  GPU workloads inherit the established locking and audit posture.

## Baseline implementation to acknowledge
### Orchestration and health coverage
`compose.yaml` expresses all services, profiles, healthchecks, volumes, and GPU bindings already shipped with
SHS. This is the operational reference the plan needs to align with, not replace.【F:compose.yaml†L1-L244】

### Digest locking and environment flow
`locks/VERSIONS.lock` stores image references, digests, and metadata, while `.env.example` mirrors those
values for local overrides. Operators copy the template to `.env.local` and run `make bootstrap`, ensuring one
source of truth for runtime digests.【F:locks/VERSIONS.lock†L1-L43】【F:.env.example†L1-L64】

### Automation entry points
`make lock`, `make sbom`, `make audit`, and `make reproduce` already call into the Python and shell helpers
that produce SBOMs, run scans, and guard reproducibility. These commands serve as the extension hooks for any
future digest-resolution features.【F:Makefile†L95-L166】【F:scripts/build_lock.py†L1-L42】【F:scripts/sbom_generate.sh†L1-L29】【F:scripts/audit.sh†L1-L34】

## Mapping the proposal to SHS layers
| Proposal theme | SHS source of truth | Integration note |
| --- | --- | --- |
| New `stack/` directory layout with bespoke profiles | House layout already codified via README atlas and compendium chapters for Fundament → Stable.【F:README.md†L35-L135】【F:docs/project-compendium.md†L7-L103】 | Preserve the existing structure; incorporate additional guidance by extending Basement/Wardrobe docs instead of introducing a parallel tree. |
| Pipe-delimited lockfile consumed directly by Compose | YAML lockfile + `.env` digests already drive Compose and automation targets.【F:locks/VERSIONS.lock†L1-L43】【F:.env.example†L1-L64】【F:Makefile†L95-L166】 | Enhance `scripts/build_lock.py` to resolve tags when needed, but retain the schema and downstream consumers. |
| Separate tag variables resolved at runtime | Current `.env.example` inlines digests to avoid drift and duplicate bookkeeping.【F:.env.example†L18-L64】 | Document how to update digests through the existing lock/`make` workflow rather than adding indirection. |
| Dedicated Automatic1111 build and GPU gating | Present GPU focus is Ollama behind a `gpu` profile with NVIDIA runtime and device bindings.【F:compose.yaml†L215-L233】 | Treat additional GPU workloads as Wardrobe overlays once governance and resource planning are recorded. |
| Additional GitHub workflow for digest verification | Make targets `lock`, `sbom`, `audit`, and `reproduce` already encapsulate the required steps for CI reuse.【F:Makefile†L95-L166】 | Build any new pipeline on top of these targets to avoid configuration drift. |

## Integration backlog
1. **Document the update loop end-to-end:** Extend the Basement section in the compendium to point to this
   review and summarise the `make lock → make sbom → make audit` lifecycle so contributors know where to hook
   digest resolution logic.【F:docs/project-compendium.md†L40-L47】【F:Makefile†L95-L166】
2. **Enhance the lock builder instead of replacing it:** Add tag-to-digest resolution to
   `scripts/build_lock.py` (or a companion helper) so that future tag references still emit the canonical YAML
   schema consumed by `make reproduce`.【F:scripts/build_lock.py†L1-L42】【F:Makefile†L95-L166】
3. **Clarify GPU roadmap ownership:** Use the Wardrobe chapter to capture when GPU overlays (e.g., Stable
   Diffusion) would be introduced, ensuring Ollama continues to represent the default GPU consumer until that
   decision is ratified.【F:docs/project-compendium.md†L48-L55】【F:compose.yaml†L215-L233】
4. **Surface cross-links in the newcomer atlas:** Update the README document list so that operators discover
   this integration guide alongside the audit and architecture references.【F:README.md†L48-L58】

## Open coordination topics
- Confirm whether Ollama remains containerised in all environments or if certain hosts plan for a native
  deployment; the choice drives how `.env.local` and Compose expose ports and health probes.【F:compose.yaml†L215-L233】【F:.env.example†L62-L64】
- Decide where Automatic1111 or comparable GPU workloads would live (Wardrobe overlay vs. Stable), then
  capture the decision in the governance backlog before introducing new Dockerfiles.【F:docs/project-compendium.md†L48-L55】
- Align on CI coverage so any future GitHub workflows simply execute the existing Make targets and publish the
  resulting SBOM and audit artefacts.【F:Makefile†L95-L166】
