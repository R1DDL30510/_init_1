#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/.codex"
if [ ! -f "$HOME/.codex/config.toml" ]; then
  cat > "$HOME/.codex/config.toml" <<'TOML'
[model_providers.ollama]
name = "Ollama (Host)"
base_url = "http://host.docker.internal:11434/v1"
wire_api = "chat"

[profiles.gar-prod]
model_provider = "ollama"
model = "gpt-oss:20b"
TOML
fi
echo "[setup-codex] Profile ready. Use: codex --profile gar-prod /status"
