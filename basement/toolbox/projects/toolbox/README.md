# Toolbox Project (Vorbereitung)

Dieses Projekt bündelt die geplante Docker-Stack-Integration von Codex CLI, lokaler Ollama-Instanz und MCP Toolkit Gateway.
Momentan dient der Ordner nur als Sammelstelle für Anforderungen und Abhängigkeiten.
Do not ablegen funktionierende Compose-Dateien oder Secrets, bevor das Konzept freigegeben ist.

## Baseline-Abhängigkeiten (Stand)
- Host: macOS 26.0 (arm64) mit Docker Desktop 4.47.0 / Engine 28.4.0 (`fundament/versions.yaml`).
- Toolbox-Paketbasis: Homebrew-Inventar unter `../inventories/Brewfile` und `../inventories/homebrew-versions.txt`.
- Kernwerkzeuge: Codex CLI 0.42.0 (Container, offizielles Release), Python 3.12/3.13, git 2.50.1 (Apple Git-155), ffmpeg 8.0_1, jq 1.8.1, yq 4.47.2.
- Host-Ollama 0.12.3 läuft separat (`ollama serve`) und stellt `gpt-oss:20b` bereit; Alternativmodelle via `ollama pull <name>`.
- Hinweis: Host-seitig bleibt Codex CLI 0.42.0 über Homebrew installiert; Container nutzt weiterhin die offizielle Release-Version.
- Geplante Erweiterungen: MCP Toolkit Gateway Container, Docker-Netzwerke/Volumes aus dem Fundament-Layer.
Do not ergänzen spezifische Image-Tags oder Secrets, solange die Architektur nicht abgestimmt ist.

## Zielbild: Minimaler Docker-Compose-Stack
| Dienst | Rolle | Wichtige Eigenschaften |
| ------ | ----- | ---------------------- |
| `codex-cli` | Bereitstellung einer interaktiven CLI, erreichbar über den Alias `gcodex`. | Eigenes, schlankes Image auf Basis von `debian:bookworm-slim` (siehe `containers/codex-cli/Dockerfile`). Lädt das offizielle OpenAI-Binary `codex` (0.42.0) + Basis-Tools (z. B. `curl`, `jq`). Startet im Shared Folder `/workspace`. Verbindung ausschließlich zum Host-Ollama (`host.docker.internal:11434`). |
| Host-Ollama | Bereitstellung der Modelle (`gpt-oss:20b` als Default). | Läuft separat auf macOS (`ollama serve`). Modelle liegen unter `/Users/garvis/.ollama`. Compose greift per `OLLAMA_HOST=http://host.docker.internal:11434` darauf zu. |
| `shared` (Bind Mount) | Gemeinsamer Arbeitsbereich für CLI und Host. | Wird in `codex-cli` als `/workspace` gemountet (`./shared:/workspace`). Dient als Austauschfläche für Skripte, Ergebnisse und Modellkonfigurationen. |

Optionale Erweiterung (später): `mcp-gateway` als dritter Service, der Zugriff auf Toolbox-Werkzeuge über MCP-Schnittstellen bereitstellt.

-### Compose-Datei (Draft)
- Speicherort: `basement/toolbox/docker-compose.draft.yml`
- Host vorbereiten: `ollama serve` starten (oder sicherstellen, dass der Dienst läuft) und Modelle unter `/Users/garvis/.ollama` bereithalten (`ollama pull gpt-oss:20b`).
- Container starten: `docker compose -f basement/toolbox/docker-compose.draft.yml up codex-cli` bzw. `run --rm codex-cli` für Einzelsessions.
- Build-Test nur für CLI: `docker compose -f basement/toolbox/docker-compose.draft.yml build codex-cli`
- Codex-Konfiguration liegt innerhalb des Containers unter `/home/coder/.codex/config.toml` und setzt per Default `model_provider = "ollama"` sowie das Profil `garvis`.

### Compose-Draft (Pseudocode)
```yaml
services:
  codex-cli:
    build: ./containers/codex-cli  # Dockerfile auf Basis von debian:bookworm-slim
    command: ["/bin/bash"]        # Einstiegspunkt überschreibbar für interaktive Sessions
    environment:
      - OLLAMA_HOST=http://host.docker.internal:11434
    volumes:
      - ./shared:/workspace
    working_dir: /workspace
```
_Do not als echte Compose-Datei verwenden, solange der Build-/Release-Prozess nicht freigegeben ist._
```
_Do not als echte Compose-Datei verwenden, solange der Build-/Release-Prozess nicht freigegeben ist._

### CLI-Alias `gcodex`
- Host-Skript: `basement/toolbox/bin/gcodex`
  ```bash
  ./basement/toolbox/bin/gcodex             # interaktive Sitzung (TTY vorausgesetzt)
  ./basement/toolbox/bin/gcodex --version   # Beispiel für non-interaktiven Aufruf
  ```
- Das Skript sorgt für `/workspace`-Mount, baut fehlende Verzeichnisse und leitet alle Parameter an `codex --profile garvis` weiter.
- Erkennt automatisch, ob ein TTY vorhanden ist (`-it` vs. `-i`), damit sowohl interaktive Chats als auch Einmalbefehle funktionieren.

## Offene Planungsfragen
- Finaler Installationsweg für `codex` im Container (derzeit: offizielles Release-Binary, Sicherheitsreview ausstehend).
- Benötigte Zusatztools im CLI-Image (Python, `jq`, `yq`?), Abgleich mit `../inventories/Brewfile`.
- Umgang mit Credentials/API-Keys: wahrscheinlich `.env.local` auf Host-Seite + Weitergabe über Compose.
- Logging-Strategie: Rotierung, Ablage im Shared Volume oder späterer Export.
- MCP-Gateway-Spezifikation: Schnittstellen, erforderliche Tools, Sicherheitsmodell.

## Pending Tasks
1. Basisimage für `codex-cli` finalisieren, Dockerfile-Konzept in `containers/codex-cli/` vorbereiten (Sicherheitsreview ausstehend).
2. Compose-Skelett in eine Draft-Datei (`docker-compose.draft.yml`) übertragen und intern reviewen.
3. Modell-Download-Strategie festhalten (`ollama pull <modell>` auf dem Host; `gpt-oss:20b` liegt bereits im Cache).
4. Benutzerfreundlichen Einstieg weiter verfeinern (z. B. `gcodex`-Wrapper in höhere Layer promoten, Logging/Tracing ergänzen).
5. Sicherheits- und Isolationsanforderungen (Mounts, Ports, Netzwerk) prüfen und dokumentieren.
6. MCP-Gateway als Anschlussmodul beschreiben (Abhängigkeiten, Ports, Schnittstellen) – erst nach Fertigstellung des Minimal-Stacks.

## Testschritte (Draft)
- `docker compose -f basement/toolbox/docker-compose.draft.yml build codex-cli`
  Prüft, ob die Config in das Image kopiert wird.
- `./basement/toolbox/bin/gcodex --version`
  Erwartung: Startet `codex --profile garvis --version` im Container und bestätigt `codex-cli 0.42.0`.
- `docker compose -f basement/toolbox/docker-compose.draft.yml run --rm codex-cli codex --version`
  Erwartung: Gibt `codex-cli 0.42.0` aus (Binary aus dem Container).
- `docker compose -f basement/toolbox/docker-compose.draft.yml run --rm codex-cli codex --profile garvis "ping"`
  Erwartung: Antwort der Host-Ollama-Instanz ohne Cloud-Zugriff (nutzt `gpt-oss:20b`, alternative Modelle nach Pull verfügbar).
- `docker compose -f basement/toolbox/docker-compose.draft.yml run --rm codex-cli cat /home/coder/.codex/config.toml`
  Verifiziert, dass die Datei die GARVIS-Defaults (`model_provider = "ollama"`) enthält.
Do not starten Implementierung, bevor alle Abhängigkeiten und Sicherheitsanforderungen dokumentiert sind.
