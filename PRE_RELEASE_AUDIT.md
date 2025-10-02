# Pre‑Release Audit & Scoring

This audit summarises the current state of the repository, scores key areas on a 1‑5 scale (5 = excellent, 1 = needs work) and lists concrete actions each owner could take before a production release.

---

## 1. Repository Structure (Score = 4)

* **Fundament/** – Baselines are present but lack detailed versioning docs.
* **Basement/** – Core scaffolding in place, but some stub services in `g-ollama` / `g-openwebui` have only a Dockerfile and README.
* **Wardrobe/Entrance/Stable** – Reserved folders are empty; no gating logic is implemented.
* **Documents** – Draft compose notes are in `basement/toolbox/documents/draft-compose-notes.md` but not referenced by CI.
  
**Action** – Create a `docs/` top‑level folder that aggregates all read‑mes, diagrams, and architectural notes. Move draft‑compose‑notes.md here.

## 2. Build & Deployment (Score = 3)

* `Makefile` is present but has no `build` target; many scripts run manually.
* Dockerfiles exist but none are built by CI.
* `scripts/` contains a handful of shell utilities that terminate early.
* `ollama serve` must be started manually before `gcodex` runs.

**Action** – Add a `make build` target that:
  - pulls latest Ollama image.
  - builds `basement/toolbox/containers/codex-cli`.
  - runs unit‑style tests.
  - tags final image as `latest`.
  - push to a registry only after a successful pre‑release review.

## 3. Continuous Integration (Score = 2)

* CI config in `basement/toolbox/ci/validate.yml` only runs the `preflight.sh` script.
* No automated linting, formatting, or security scans.
* Acceptance tests in `tests/acceptance/` are shell scripts but no pipeline triggers them.

**Action** – Expand CI to include:
  - linting (`yamllint`, `shellcheck`).
  - static analysis for Dockerfiles (`hadolint`).
  - run acceptance tests via `tests/acceptance/`.
  - use `actionlint` to validate GitHub Actions.
  - require a `--dry-run` step before merging into the `Stable` branch.

## 4. Documentation (Score = 4)

* `README.md` provides a high‑level overview but is missing a quick‑start guide.
* `basement/toolbox/docs/overview.md` exists but is very light.
* Diagrams folder is empty.
* No contribution guide beyond `AGENTS.md`.

**Action** – Add:
  - a `CONTRIBUTING.md` with issue/PR workflow.
  - quick‑start section in `README` that shows how to spin‑up the stack.
  - a diagram in `docs/arch.svg` or `docs/arch.md` illustrating layers.

## 5. Security (Score = 3)

* Secrets are expected in `.env.local` and ignored in `.gitignore`.
* No SCA (software composition analysis) or vulnerability scanning.
* `SECURITY.md` exists in root but lacks actionable CVE policies.

**Action** – Introduce:
  - GitHub CodeQL workflow.
  - Dependabot or Renovate bot to auto‑update dependencies.
  - A `SECURITY.md` section that lists vulnerable versions to avoid.

## 6. Testing (Score = 1)

* No automated test framework.
* Acceptance shell scripts exist but require manual execution.

**Action** – Pick a lightweight test runner (e.g., `bats` for bash or Python `pytest` if using python layers). Implement at least:
  - unit tests for critical functions.
  - integration tests that spin up a minimal service stack.
  - CI step to run tests before merging.

---

## Overall Score
```
Structure: 4
Build:      3
CI:         2
Docs:       4
Security:   3
Testing:    1
=====================
Total:      17/30
```

With these improvements the repository will be ready for a stable release.

---

### Responsibility Matrix

| Role | Primary Tasks |
|------|---------------|
| Maintainer | Oversee build pipeline, merge approvals, final release. |
| CI Engineer | Implement CI workflows, linting, tests, security scans. |
| Documentation Lead | Expand `README`, `CONTRIBUTING`, and diagram assets. |
| Security Officer | Set up CodeQL, Dependabot, enforce secret policies. |
| Contributor | Submit PRs with updated tests and code; follow guidelines. |

---

### Next Steps
1. Generate `CONTRIBUTING.md` and `docs` structure. |
2. Implement CI enhancements. |
3. Add tests and make targets. |
4. Review `SECURITY.md` and configure CodeQL. |
5. Conduct a dry‑run release to `Stable` and gather feedback.

---

Prepared by the codex‑assistant, October 2 2025.
