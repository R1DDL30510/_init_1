Die Toolbox ist das Mono-Repo-Skelett des Hauses und dient als Referenzbewohner
im Basement. Sie bündelt Kataloge, Projekte und Automationsentwürfe, die später
in Wardrobe, Entrance und Stable promotet werden können.

## Inhalte
- `catalog/`, `schemas/`, `projects/`: Draft-Strukturen für Tool- und
  Projektkataloge.
- `scripts/`, `ci/`: Platzhalter für künftige Automationen, noch ohne Logik.
- `inventories/`: Homebrew-Bundle (`Brewfile`) und vollständige
  Versionsliste (`homebrew-versions.txt`).
- `documents/`: Entwürfe wie `draft-compose-notes.md` für Compose-Planung.
- `containers/`: Dockerfile-Sammlung (z. B. `codex-cli/` auf Basis
  `debian:bookworm-slim`).
- `bin/gcodex`: Host-Wrapper, der `docker compose … codex --profile garvis` mit
  `/workspace`-Mount startet.
- `projects/toolbox/`: Dokumentation des geplanten Compose-Stacks (Codex im
  Container, Ollama als Host-Service).

Weitere Hintergründe liefert das [Toolbox-Dossier](../../docs/projects/toolbox.md).

Do not deploy produktive Services oder echte Artefakte, solange der Transfer in
höhere Layer aussteht.
