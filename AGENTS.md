# Repository Guidelines

This guide is a quick reference for contributors.  Read it before making changes.

## 1. Project Structure & Module Organization

| Folder | Purpose |
|--------|---------|
| **Fundament/** | Baselines (OS, Docker, Git) & promotion notes – *no source code*.
| **Basement/** | Naked service stubs + `toolbox/` scaffold.  Draft compose files live in `basement/toolbox/documents/`.
| **Wardrobe/**, **Entrance/**, **Stable/** | Reserved for overlay, pre‑release, and production stages – currently empty.
| **tests/** | Acceptance‑shell scripts that confirm the stack works.

**Example** – a new component should live in
```bash
basement/toolbox/projects/toolbox/new‑feature/PROJECT.yaml
```

## 2. Build, Test, and Development Commands

* `ollama serve` – starts the model server (port 11434). Must run before further steps.
* `./basement/toolbox/bin/gcodex` – launch an interactive Codex session (`codex --profile garvis`).
* `./basement/toolbox/bin/gcodex --version` – quick smoke‑test.
* `make build` – *(planned)* will build `codex-cli` and run basic checks.

Scripts are kept in `basement/toolbox/scripts/`; keep each one short and quit early if possible.

## 3. Coding Style & Naming Conventions

* **YAML** – 2‑space indent.  **Markdown code blocks** – 4‑space indent.
* **File names** – lowercase‑dash, e.g., `draft-compose-notes.md`.
* **Project slugs** – `area-topic-scope` (see `projects/_template/PROJECT.yaml`).
* **Timestamps** – `YYYY‑MM‑DDThh-mm-ssZ` (e.g., `2024‑10‑02T14‑30‑00Z`).
* **Placeholders** – keep `# Do not …` comments until the section is finished.

No linting tool is required; just mimic the style of existing files.

## 4. Testing Guidelines

The repo has no automated test framework yet.  When adding tests:

* Put test scripts in `basement/toolbox/scripts/`.
* Name them after the component under test, e.g., `validate_repo_test.py`.
* Explain how to run them in `basement/toolbox/docs/overview.md`.

Future plans: integrate `bats` (bash) or `pytest` (Python).

## 5. Commit & Pull Request Guidelines

* **Commit messages**: imperative, mention the affected layer.
  Example: `Basement: Add new compose draft`.
* **Pull requests**: concise description, link to relevant docs.
  Keep placeholder warnings if intentional.
* **Screenshots**: include only when they clarify a change.

## 6. Security & Configuration Tips

* Store secrets in `.env.local` (ignored by Git) – never commit them.
* Shared volumes expose only `./shared` by default.
* Document new dependencies in `fundament/versions.yaml` or inside `basement/toolbox/inventories/`.

