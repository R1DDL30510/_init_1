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

Do not in produktive Compose-Dateien übernehmen, bevor die Architektur freigegeben ist.
