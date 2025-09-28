# Toolbox Project (Vorbereitung)

Dieses Projekt bündelt die geplante Docker-Stack-Integration von Codex CLI, lokaler Ollama-Instanz und MCP Toolkit Gateway.
Momentan dient der Ordner nur als Sammelstelle für Anforderungen und Abhängigkeiten.
Do not ablegen funktionierende Compose-Dateien oder Secrets, bevor das Konzept freigegeben ist.

## Verifizierter Stand (2024-12-05)

| Bereich | Status | Nachweis |
| ------ | ------ | -------- |
| Container-Build `codex-cli` | ✅ Verifiziert | `docker compose -f basement/toolbox/docker-compose.draft.yml build codex-cli` erstellt das Image mit `/workspace`-Mount. |
| Einstieg über `bin/gcodex` | ✅ Verifiziert | `./basement/toolbox/bin/gcodex` verbindet gegen `http://host.docker.internal:11434` und ermöglicht interaktive Sessions mit Host-Ollama. |
| Netzwerkgrenzen | ✅ Verifiziert | Container spricht ausschließlich den Host an; keine zusätzlichen Ports/Netzwerke aktiviert. |

## Version Pinning & Abhängigkeiten

| Komponente | Stabiler Stand | Status | Notizen |
| ---------- | ------------- | ------ | ------- |
| Codex CLI (Container) | 0.42.0 | ✅ Verifiziert | Offizielles Release-Binary im Image `codex-cli`. |
| Codex CLI (Host) | 0.42.0 | ✅ Verifiziert | Bleibt über Homebrew installiert, dient als Fallback. |
| Ollama (Host) | 0.12.3 | ✅ Verifiziert | Läuft via `ollama serve`, stellt u. a. `gpt-oss:20b` bereit. |
| Docker Desktop / Engine | 4.47.0 / 28.4.0 | ✅ Verifiziert | Referenz laut `fundament/versions.yaml`. |
| MCP Gateway Dienst | _tbd_ | ⏳ Zu verifizieren | Compose-Service mit fixiertem Image-Tag und dediziertem Tool-Rechteprofil notwendig. |
| Compose-Datei | Draft | ⏳ Zu verifizieren | `docker-compose.draft.yml` benötigt Hardening (Volumes, Netzwerke, Policies) vor Promotion. |

## Zu verifizieren (Next Steps)

1. **Version Pinning finalisieren** – Ziel-Tags/Release-Stände für neue Services (MCP Gateway, optionale Utilities) definieren und in den Inventories dokumentieren.
2. **Compose-Hardening** – Netzwerk-/Volume-Richtlinien, optionale `profiles` sowie read-only Mounts für den Draft ausarbeiten.
3. **Security Review** – Secrets-Fluss (`.env.local`, Bind-Mounts) und Audit-Logging-Konzept festlegen.
4. **MCP Endpoint Smoke-Testplan** – Erfolgskriterien und Testbefehle dokumentieren, bevor Implementierung startet.

## Zielbild: Minimaler Docker-Compose-Stack
| Dienst | Rolle | Wichtige Eigenschaften |
| ------ | ----- | ---------------------- |
| `codex-cli` | Bereitstellung einer interaktiven CLI, erreichbar über den Alias `gcodex`. | Eigenes, schlankes Image auf Basis von `debian:bookworm-slim` (siehe `containers/codex-cli/Dockerfile`). Lädt das offizielle OpenAI-Binary `codex` (0.42.0) + Basis-Tools (z. B. `curl`, `jq`). Startet im Shared Folder `/workspace`. Verbindung ausschließlich zum Host-Ollama (`host.docker.internal:11434`). |
| Host-Ollama | Bereitstellung der Modelle (`gpt-oss:20b` als Default). | Läuft separat auf macOS (`ollama serve`). Modelle liegen unter `/Users/garvis/.ollama`. Compose greift per `OLLAMA_HOST=http://host.docker.internal:11434` darauf zu. |
| `shared` (Bind Mount) | Gemeinsamer Arbeitsbereich für CLI und Host. | Wird in `codex-cli` als `/workspace` gemountet (`./shared:/workspace`). Dient als Austauschfläche für Skripte, Ergebnisse und Modellkonfigurationen. |

Optionale Erweiterung (später): `mcp-gateway` als dritter Service, der Zugriff auf Toolbox-Werkzeuge über MCP-Schnittstellen bereitstellt.

### MCP Endpoint Planung (Entwurf)

1. **Service-Spezifikation**
   - Kandidat: Docker Desktop `mcp_gateway` Image oder alternative, selbst verwaltete Gateway-Implementierung mit klaren Tool-Freigaben.
   - Endpunkt soll Codex CLI (Container) sowie Host-Ollama bedienen können, ohne zusätzliche Internet-Exponierung.
2. **Sicherheits- und Rechte-Modell**
   - Least-Privilege: Nur benötigte Tools (z. B. Dateizugriff auf `/workspace`, Bildextraktion, Shell-Kommandos) freischalten.
   - Geheimnisse via `.env.local` + Compose-Environment injizieren; Audit-Logs im Shared Volume sammeln.
3. **Netzwerk-Layout**
   - Separates internes Compose-Netz zwischen `codex-cli` und `mcp-gateway`; Host-Zugriffe nur über definierte Gateways.
   - Optionaler Reverse-Proxy, falls externe Clients angebunden werden müssen.
4. **Integrations-Checks**
   - Testfall: `codex` nutzt MCP Tools für Dateizugriff (z. B. Bild-Pipeline) innerhalb des Containers.
   - Testfall: Zugriff auf Host-Ollama bleibt unverändert (weiterhin via `OLLAMA_HOST`).
5. **Promotion-Kriterien**
   - Dokumentierte Version-Pins, Security Review und Freigabe.
   - Erfolgreiche Smoke-Tests (`docker compose run mcp-gateway --health-check`, `codex --profile garvis --tool <mcp-tool>`).

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
- Benötigte Zusatztools im CLI-Image (Python, `jq`, `yq`?) im Vergleich zu `../inventories/Brewfile`.
- Secrets-Handling: `.env.local` auf Host-Seite, Weitergabe via Compose und zukünftige Rotation.
- Logging-Strategie: Rotierung, Ablage im Shared Volume oder Export in höhere Layer.
- MCP-Gateway-Konfiguration: Tool-Liste, Rollenmodell, Interaktion mit Docker Desktop `mcp_gateway` oder Alternativen.
- Wardrobe-Integration: Definition der Overlays, die macOS- und Windows-/NVIDIA-Hosts ohne erneutes Provisioning unterstützen.

## Pending Tasks
1. Basisimage für `codex-cli` finalisieren, Dockerfile-Konzept in `containers/codex-cli/` vorbereiten (Sicherheitsreview ausstehend).
2. Compose-Skelett in eine Draft-Datei (`docker-compose.draft.yml`) übertragen und intern reviewen.
3. Modell-Download-Strategie festhalten (`ollama pull <modell>` auf dem Host; `gpt-oss:20b` liegt bereits im Cache).
4. Benutzerfreundlichen Einstieg weiter verfeinern (z. B. `gcodex`-Wrapper promoten, Logging/Tracing ergänzen).
5. Sicherheits- und Isolationsanforderungen (Mounts, Ports, Netzwerk) prüfen und dokumentieren.
6. Wardrobe-Overlays für Multi-Host-Einsatz beschreiben und konsistente Shared-Workspace-Struktur sicherstellen.
7. MCP-Gateway-Modul mit klarer Versionierung beschreiben (Abhängigkeiten, Ports, Schnittstellen) – Umsetzung nach Abschluss der Vorarbeiten.

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
- `docker compose -f basement/toolbox/docker-compose.draft.yml run --rm mcp-gateway --health-check`
  Geplanter Test, sobald der Dienst definiert ist (Healthcheck muss erfolgreichen Start und Tool-Registrierung melden).
- `./basement/toolbox/bin/gcodex --tool <mcp-tool> --dry-run`
  Geplanter Test, um MCP-Tool-Aufrufe über die CLI zu validieren.
Do not starten Implementierung, bevor alle Abhängigkeiten und Sicherheitsanforderungen dokumentiert sind.
