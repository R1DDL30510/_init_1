# Professor Audit – Run 1 (2025-02-15)

## Gesamtüberblick
- **Umfang:** Vollständige Durchsicht der House-Layer, Compose- und Skriptlandschaft sowie der veröffentlichten Dokumentation.
- **Methodik:** Statische Analyse von YAML/Shell/Dockerfiles, Querprüfung von Dokumentverweisen und Plausibilitätscheck der Backup-/Restore-Kette.

## 1. Code-Qualität & Stil — Note: ausreichend
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Floating Base Image & TODO-Reste | `basement/g-openwebui/Dockerfile` | Ungeprüftes `FROM ghcr.io/open-webui/open-webui:main` plus offene TODOs verhindert reproduzierbare Reviews und verletzt Layer-Vorgaben. | Feste Version + Digest pinnen, TODOs schließen oder klar als Stub markieren. |
| Shell Supply Chain Kontrolle fehlt | `basement/toolbox/containers/codex-cli/Dockerfile` | `curl` lädt Binärpakete ohne Signatur-/Checksum-Prüfung; erhöht Supply-Chain-Risiko. | SHA256-Prüfung oder Signaturverifikation ergänzen, Download-URL versionieren. |

**Zusatzbeobachtung:** `scripts/tls/export_client_bundle.sh` besitzt einen versehentlichen führenden Leerraum vor `done`; geringe, aber zu bereinigende Stilabweichung.

## 2. Struktur & Modularität — Note: befriedigend
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Gemeinsames Log-Volume koppelt Dienste | `compose.yaml` | Jede Komponente bindet `./logs` schreibend ein; dadurch fehlen Isolation & Rotationsgrenzen. | Für jede Rolle eigene Volume-Buckets oder Aggregation via Forwarder vorsehen. |
| Layer-Pollution durch macOS-Metadaten | `wardrobe/.DS_Store`, `entrance/.DS_Store`, `stable/.DS_Store` | Git-tracked Finder-Artefakte widersprechen House-Governance und erschweren Promotions. | Dateien löschen, `.gitignore` respektieren, Pre-commit-Hook ergänzen. |

## 3. Dokumentation & Lesbarkeit — Note: ausreichend
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Verweis auf nicht existierende Spezifikation | `docs/project-compendium.md`, `docs/pre-release-audit.md` | Link auf `docs/library-schema.md`, Datei fehlt → Navigation bricht. | Stub anlegen oder Verweis entfernen, bis Inhalt bereitsteht. |
| Falscher Test-Name im Playbook | `docs/runbook-ga-02-delete-playbook.md` | Referenz auf `tests/acceptance/06_delete.sh`, existiert nicht (tatsächlich `06_resilience.sh`). | Dokument aktualisieren und echten Delete-Test (GA-02) dokumentieren. |

## 4. Sicherheit & Privacy — Note: befriedigend
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Unverifizierte Binaries im Toolbox-Container | `basement/toolbox/containers/codex-cli/Dockerfile` | Fehlende Checksum-Validierung ermöglicht Binär-Tampering. | Checksum/Signature prüfen; ggf. internen Artifact-Mirror nutzen. |
| Backup enthält private TLS-Keys im Klartext | `scripts/backup.sh` | Archiv speichert CA- & Leaf-Keys unverschlüsselt; Risiko bei Offsite-Transfer. | Archiv mit `age`/`gpg` verschlüsseln oder Secure-Store definieren. |

**Zusatz:** Compose übergibt alle Secrets via Umgebungsvariablen; Evaluierung eines Secrets-Backends (z. B. Docker Secrets) empfohlen.

## 5. Funktionalität & Korrektheit — Note: ausreichend
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Sync-Test trifft falsches Artefakt | `tests/acceptance/05_sync.sh` | Entfernt nur lokale Dateien (`-f`), obwohl `uri` als `s3://` gespeichert wird → Test prüft reale Sync-Pfade nicht. | S3-/MinIO-Aufräumroutine einbauen oder URI parsing ergänzen. |
| Delete-Drill fehlt | `docs/runbook-ga-02-delete-playbook.md` & Tests | Playbook verweist auf nicht existierende Automatisierung; funktionale Lücke für GA-02. | Delete-Testskript implementieren, Runbook & Acceptance Suite synchronisieren. |

## 6. Outdated / Unreferenced / Undocumented — Note: mangelhaft
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Fehlende Bibliotheks-Doku | `docs/project-compendium.md`, `docs/pre-release-audit.md` | Geplanter Knowledge-Base-Guide nicht vorhanden, trotzdem mehrfach verlinkt. | Platzhalterdatei erstellen inkl. Hinweis auf offenen Status. |
| Finder-Dateien trotz Ignore-Regel | `wardrobe/.DS_Store`, `entrance/.DS_Store`, `stable/.DS_Store` | Historische Artefakte verwirren Reviewer & verletzen AGENTS-Vorgaben. | Dateien entfernen, CI-Lint ergänzen. |

## 7. Reproduzierbarkeit — Note: mangelhaft
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Unvollständige Pinning-Matrix | `VERSIONS.lock` | Alle Digest-Felder stehen auf `***FILL***`; Compose greift nur Tags aus `.env`. | Digests ermitteln, `compose_schema_sha256` pflegen, Validierungsskript ergänzen. |
| Floating Compose-Images | `.env.example`, `compose.yaml` | Image-Variablen erlauben Tag-Drift; Dokumentation behauptet deterministische Pins. | Compose auf Digests umstellen oder Versions-Gate im Makefile erzwingen. |

## Gesamturteil
- **Gesamtnote:** 3,0 (befriedigend) – solide Grundstruktur, aber reproduzierbare Lieferfähigkeit und Dokumentationskohärenz müssen vor einer Promotionsentscheidung verbessert werden.

## To-Do (für nächstes Commit)
1. Digests in `VERSIONS.lock` nachziehen und Compose gegen `@sha256` sichern.
2. Toolbox- & Basement-Dockerfiles mit verifizierten Quellen/Digests härten.
3. `docs/library-schema.md` als Stub inkl. Status-Hinweis anlegen oder Links entfernen.
4. Acceptance-Sync-Test an echten Storage-Pfad anpassen; Delete-Drill implementieren bzw. dokumentieren.
5. Git-Repository von `.DS_Store` bereinigen und Guard hinzufügen.
6. Backup-Artefakte verschlüsseln oder klar dokumentierte Storage-Policies ergänzen.

## Mündlicher Kommentar
> "Die Hausmetapher steht, aber die Türen quietschen noch. Bevor ich die Promotionsglocke läute, liefern Sie bitte harte Digests, einen echten Delete-Drill und entsorgen Sie die Finder-Souvenirs. Dann reden wir weiter."
