Fundament layer sammelt Basis-Konfigurationen und gemeinsame Vorbereitungen.
Es dient als Ausgangspunkt für Netzwerke, Volumes und künftige Host-Prüfungen.
Aktueller Überblick: siehe ../docs/revision-2025-09-28.md (Layer Snapshot "Fundament").
Do not hinterlege laufzeitkritische Overrides oder produktive Zugangsdaten hier.

## Host-Baselines (Stand)
- macOS 26.0 (arm64) als Hostplattform
- Docker Desktop 4.47.0 / Engine 28.4.0 (API 1.51, containerd 1.7.27, runc 1.2.5)
- Git 2.50.1 (Apple Git-155) als hostweites SCM-Tool

## Referenzen
- Weitere Tool- und Projektabhängigkeiten: `basement/toolbox/inventories/`
- Promotion-Gates & Verifizierung: `STATE_VERIFICATION.md`
