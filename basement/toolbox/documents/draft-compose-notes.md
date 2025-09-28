# Draft Compose Notes

Dieser Entwurf dient als spätere Vorlage für die `docker-compose.yml`, sobald die Toolbox implementiert wird.

## Services
- `codex-cli`
  - Build-Kontext: `./containers/codex-cli`
  - Basisimage: `debian:bookworm-slim`
  - Installiert `codex`, grundlegende CLI-Tools, optional Python.
  - Environment: `OLLAMA_HOST=http://host.docker.internal:11434`
  - Command: `/bin/bash` (interaktive Shell) oder direkt `codex`
  - Volumes: `shared-data:/workspace`
- `ollama`
  - Image: `ollama/ollama:latest`
  - Volumes: `shared-data:/workspace`; `ollama-models:/root/.ollama`
  - Ports: 11434 intern, optional nach außen
- Volumes:
  - `shared-data`: bindet Host `./shared`
  - `ollama-models`: persistente Modelldaten

## Optional
- `mcp-gateway` Dienst, sobald Tool-Integration konkret ist.

## Statusübersicht
- **Verifiziert**
  - `codex-cli` Build über `docker compose -f basement/toolbox/docker-compose.draft.yml build codex-cli`.
  - Zugriff auf Host-Ollama (`OLLAMA_HOST=http://host.docker.internal:11434`) durch `bin/gcodex`.
- **Zu verifizieren**
  - Endgültige Compose-Policies (Netzwerke, Volumes, Profiles).
  - Gesundheitsprüfung und Tool-Registrierung eines `mcp-gateway` Dienstes.
  - Dokumentierte Version-Pins für zusätzliche Services.

## MCP Endpoint Plan (Draft)
1. **Image- & Versionswahl**
   - Kandidat prüfen: Docker Desktop `mcp_gateway` (Image-Tag fixieren) vs. eigenes Gateway-Image.
   - Version-Pins in `inventories/` dokumentieren, sobald festgelegt.
2. **Compose-Integration**
   - Eigenes internes Netzwerk (`toolbox-mcp`) für `codex-cli` ↔ `mcp-gateway`.
   - Volumes: read-only Zugriff auf `/workspace` für das Gateway, optional separates Log-Volume.
3. **Security & Policies**
   - Tool-Freigaben in MCP-Manifest beschränken (Dateioperationen, Bildextraktion, kontrollierte Shell-Befehle).
   - Secrets-Fluss über `.env.local` + `env_file` definieren; Audit-Logs im Shared Volume ablegen.
4. **Smoke-Tests vorbereiten**
   - `docker compose run mcp-gateway --health-check` → erwartet erfolgreiche Initialisierung.
   - `codex --profile garvis --tool <mcp-tool> --dry-run` → testet Tool-Aushandlung.
5. **Nachgelagerte Schritte**
   - Monitoring/Logging einbinden (z. B. strukturierte Logs im Shared Volume).
   - Zugangskontrolle für externe Clients (optional Reverse-Proxy, AuthN/AuthZ) planen.

## Version Pinning (Draft)
- `codex-cli`: 0.42.0 (Container & Host) – bereits geprüft.
- `ollama`: 0.12.3 (Host) – stabiler Stand, weitere Modelle via `ollama pull`.
- `mcp-gateway`: _tbd_ – festlegen, sobald Image evaluiert wurde.
- Docker Engine / Desktop: 28.4.0 / 4.47.0 – Referenzwerte laut Fundament-Layer.

Do not in produktive Compose-Dateien übernehmen, bevor die Architektur freigegeben ist.
