# House Architecture Repository

Dieses Repository beschreibt ein Haus, dessen Ebenen (Fundament, Basement,
Wardrobe, Entrance, Stable) nacheinander mit Leben gefüllt werden. Die Toolbox
ist dabei der erste Bewohner: Sie liegt im Basement und liefert das Mono-Repo
samt Codex/Ollama-Stack, auf dem weitere Projekte aufbauen.

## Dokumentationsstruktur
- [Dokumentations-Navigation](docs/README.md)
- [House-Guide](docs/house/README.md)
- [House-Blueprint](docs/house/blueprint.md)
- [Projektübersicht](docs/projects/README.md)
- [Toolbox-Dossier](docs/projects/toolbox.md)
- [Logbuch](docs/logbook/README.md)

## Aktuelle Leitplanken
- Host-Level Abhängigkeiten und Promotionskelette liegen im
  [`fundament/`](fundament/)-Verzeichnis.
- Das Basement beherbergt die Toolbox sowie Stubs für Ollama und Open-WebUI.
- Wardrobe, Entrance und Stable sind vorbereitet, bleiben aber Platzhalter bis
  die Toolbox Promotions in höhere Ebenen rechtfertigt.

## Toolbox als Referenz
- `basement/toolbox/bin/gcodex` startet Codex im Container gegen einen hostseitigen
  Ollama-Dienst (`ollama serve`).
- `basement/toolbox/projects/toolbox/` dokumentiert den Compose-Draft für den
  Stack.
- Kataloge, Inventare und Schemata werden als Blaupause für künftige Projekte
  gepflegt.

_Do not_ produktive Services oder Secrets einchecken; das Repository befindet
sich weiterhin in der Scaffold-Phase.
