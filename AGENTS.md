# Repository Guidelines

## Project Structure & Module Organization
- **Fundament/**: Host baselines (OS, Docker, Git) and promotion notes; no project code lives here.
- **Basement/**: Contains naked service stubs plus the `toolbox/` mono-repo scaffold (catalogs, schemas, projects, inventories, documents, containers). Compose drafts live under `basement/toolbox/documents/`.
- **Wardrobe/**, **Entrance/**, **Stable/**: Reserved for overlays, pre-release validation, and production rollouts; currently placeholders.
- Keep new assets within the appropriate house layer and reference shared data in `basement/toolbox/projects/` when planning updates.

## Build, Test, and Development Commands
- Kein automatisierter Build. Draft-Skripte liegen in `basement/toolbox/scripts/` und beenden sich bewusst früh.
- Für den Codex/Ollama-Stack: Host-seitig `ollama serve` starten (Port 11434). Danach `./basement/toolbox/bin/gcodex` für interaktive Sessions (`codex --profile garvis`) bzw. `./basement/toolbox/bin/gcodex --version` als Smoke-Test.
- Vor neuen Befehlen zuerst den Zweck im passenden README dokumentieren (z. B. Compose-Aufrufe in `basement/toolbox/projects/toolbox/README.md`).

## Coding Style & Naming Conventions
- Use two spaces for YAML, four spaces for Markdown code blocks, and stay in ASCII unless UTF-8 is required by upstream docs.
- Project slugs follow `area-topic-scope` (see `basement/toolbox/projects/_template/PROJECT.yaml`).
- Timestamp format: `YYYY-MM-DDThh-mm-ssZ` (filesystem safe). Maintain `Do not ...` warnings in placeholder files to signal incomplete sections.

## Testing Guidelines
- No test framework is configured. When introducing tests, describe the target coverage and invocation within `basement/toolbox/docs/overview.md` and add scripts under `basement/toolbox/scripts/`.
- Name future test files after the component under test (e.g., `validate_repo_test.py`) and ensure they can run inside the planned Docker stack.

## Commit & Pull Request Guidelines
- Write imperative, scope-aware commit messages (e.g., `Document toolbox compose plan`). Mention affected layers (Fundament/Basement/etc.) when relevant.
- Pull requests should summarize structural changes, link to planning documents (e.g., `basement/toolbox/projects/toolbox/README.md`), and confirm that placeholder warnings remain or are resolved.
- Include screenshots or command output snippets only when they aid review; otherwise describe expected outcomes textually.

## Security & Configuration Tips
- Host secrets go in `.env.local` (ignored) and must never be committed. Shared volumes should expose only `./shared` unless promotion gates approve more.
- Document new dependencies in `fundament/versions.yaml` (host-level) or `basement/toolbox/inventories/` (project-level) before shipping changes.
