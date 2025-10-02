# Toolbox-Dossier

Die Toolbox ist das erste voll dokumentierte Projekt im Haus. Sie lebt im
Basement, verbindet Host-Ressourcen mit Container-Workflows und liefert die
Referenz für künftige Bewohner.

## Auftrag
- Stellt das Mono-Repo-Gerüst für Tools, Projekte und Kataloge bereit.
- Kapselt den Codex-CLI-Container samt `gcodex`-Wrapper, während Ollama
  hostseitig läuft.
- Dokumentiert Inventare, Schemata und Compose-Drafts, die von anderen Projekten
  übernommen werden können.

## Struktur
| Pfad | Zweck |
|------|-------|
| `basement/toolbox/bin/gcodex` | CLI-Wrapper, der Codex im Container mit dem Host-Ollama verbindet. |
| `basement/toolbox/projects/toolbox/` | Compose-Entwürfe und offene Planungsfragen für den Stack. |
| `basement/toolbox/inventories/` | Wiederverwendbare Paketlisten (z. B. Homebrew). |
| `basement/toolbox/docs/` | Standards, Diagramme und Playbooks für Arbeitsabläufe. |
| `basement/toolbox/containers/` | Dockerfile-Sammlung, u. a. für den Codex-CLI-Container. |

## Promotionpfad
1. **Basement** – Planung und Entwurf (aktueller Status). Dokumentation muss im
   Dossier gepflegt werden.
2. **Wardrobe** – Wrapper und Overlays ausrollen (`bin/gcodex`, Profile für GPU/CPU/CI).
3. **Entrance** – Canary- und Telemetrie-Experimente mit echten Nutzerflüssen.
4. **Stable** – Produktionsbetrieb nach bestandenen Promotion-Gates.

## Abhängigkeiten
- Host benötigt Docker, Git und ein laufendes `ollama serve` (siehe
  [`fundament/`](../../fundament/)).
- Shared Workspace `./shared` wird zwischen Host und Codex-Container gemountet.
- Netzwerkzugriff auf `host.docker.internal:11434` für den Ollama-Endpunkt.

## Offene Aufgaben
- MCP-Gateway-Spezifikation ergänzen und im Compose-Draft verankern.
- Wardrobe-Profile (GPU, CPU, CI) mit konkreten Parametern ausstatten.
- Dokumentation der Promotion-Gates erweitern, sobald Tests und Automationen
  festgelegt sind.

## Verwandte Dokumente
- [Blueprint](../house/blueprint.md)
- [Logbuch – 2025-09-28](../logbook/2025-09-28.md)
- [Projektübersicht](README.md)
