Dieses Toolbox-Skelett bildet das Mono-Repo-Grundgerüst für Tools, Versionen und Projekte im Basement.
Es dient aktuell nur der Planung, damit der Übergang ins House-Hauptgerüst später reibungslos gelingt.
Do not deploy produktive Services oder echte Artefakte, solange der Transfer in höhere Layer aussteht.

## Inhalte
- `catalog/`, `schemas/`, `projects/`: Draft-Strukturen für Tool- und Projektkataloge.
- `scripts/`, `ci/`: Platzhalter für künftige Automationen, noch ohne Logik.
- `inventories/`: Homebrew-Bundle (`Brewfile`) und vollständige Versionsliste (`homebrew-versions.txt`).
- `documents/`: Entwürfe wie `draft-compose-notes.md` für Compose-Planung.
- `containers/`: Dockerfile-Sammlung (z. B. `codex-cli/` auf Basis `debian:bookworm-slim`).
- `bin/gcodex`: Host-Wrapper, der `docker compose … codex --profile garvis` mit `/workspace`-Mount startet. Setze `GCODEX_COMPOSE_FILE` bzw. `GCODEX_SERVICE_NAME`, um alternative Compose-Dateien oder Dienstnamen anzusprechen.
- `projects/toolbox/`: Dokumentation des geplanten Compose-Stacks (Codex CLI + Ollama + Shared Volume).

## Geplanter Stack (Kurzfassung)
- Container `codex-cli` (Basis: `debian:bookworm-slim`, liefert alias `gcodex`).
- Ollama läuft auf dem Host (`ollama serve`), Modelle liegen unter `/Users/garvis/.ollama`. Der Container spricht den Dienst via `host.docker.internal:11434` an.
- `shared/` dient weiterhin als Austauschordner zwischen Host und Container.
- MCP Gateway wird später als zusätzlicher Dienst integriert.

- **Hinweis:** Schlage im Root-`README` das Kapitel „Toolbox & gcodex“ nach, falls das Draft-Compose fehlt. Der Wrapper gibt ebenfalls eine Fehlermeldung mit Override-Hinweisen aus.

Do not verschieben diese Struktur in höhere Layer, bevor das Projekt die Promotion-Gates erfüllt.
