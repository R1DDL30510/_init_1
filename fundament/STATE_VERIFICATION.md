# State Verification

## Stable vs Experimental
Beschreibt zukünftige Übergänge zwischen stabilen und experimentellen Konfigurationen.
Do not dokumentiere hier einzelne Service-Implementierungen.

## Host-Dependencies
Erwartete Host-Baselines: Windows 11 + WSL2 + Docker Desktop (GPU support), macOS 14+ (aktuell macOS 26.0 build 25A354) mit Docker Desktop.
Zwingende Host-Werkzeuge: Docker Desktop 4.47.0 (Engine 28.4.0, API 1.51, containerd 1.7.27, runc 1.2.5), Git 2.50.1 (Apple Git-155).
Tool- und Projektabhängigkeiten werden im Basement (`basement/toolbox/inventories/`) gepflegt.
Do not ergänze Installationsskripte, solange die Anforderungen nicht final sind.

## Verification Workflow (Draft)
1. `docker version --format '{{json .}}'` und `docker info` sichern die Engine-Metadaten.
2. `git --version` prüfen, sobald Host-Updates eingespielt werden.
3. Zusätzlich benötigte Abhängigkeiten im Basement inventarisieren und versionieren.
4. Ergebnisse dokumentieren, bevor Promotion-Gates greifen.
Do not automatisieren diese Schritte, bevor ein gemeinsames Review erfolgt.

## Promotion Gates
Placeholder für Kriterien, wann Artefakte aus dem Basement höhergestuft werden.
Do not hinterlege finale Gate-Definitionen ohne Architektur-Review.
