# Professor Audit – Run 2 (2025-02-16)

## Gesamtüberblick
- **Vergleich zu Run 1:** Baseline-Hygiene wurde sichtbar verbessert (Digest-Pins für OpenWebUI, Checksums im Codex-Container, aufgeteilte Log-Volumes, verschlüsselte Backups, erweiterte Acceptance-Suite).
- **Restschulden:** Einzelne Stubs behalten ungepinnte Images, die neue Verschlüsselung ist noch nicht mit Restore/Runbook abgestimmt, und Dokumentation verspricht mehr Determinismus als tatsächlich eingelöst.

## 1. Code-Qualität & Stil — Note: befriedigend
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Ungesicherter Stub | `basement/g-ollama/Dockerfile` | Das Stub-Image verweist weiterhin nur auf den Tag `ollama:0.1.32`; ohne Digest fehlt der Supply-Chain-Schutz im Basement. | Digest aus `VERSIONS.lock` übernehmen (`FROM ollama/ollama@sha256:…`) oder Stub klar als unpromotiert kennzeichnen. |

## 2. Struktur & Modularität — Note: gut
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| – | – | Die in Run 1 bemängelte gemeinsame Log-Bind-Mount wurde behoben (pro Dienst jetzt eigenes `./logs/<svc>`-Verzeichnis). Keine neuen strukturellen Befunde. | – |

## 3. Dokumentation & Lesbarkeit — Note: befriedigend
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Backup-Artefakte falsch beschrieben | `README.md`, `RUNBOOK.md` | Beide Dokumente behaupten weiterhin, `make backup` erzeuge ein unverschlüsseltes `shs-<timestamp>.tar.zst`, obwohl seit Run 2 standardmäßig ein `*.tar.zst.age`-Archiv entsteht. | Texte und Tabellen auf den neuen Verschlüsselungs-Workflow anpassen (inkl. Hinweis auf `age`-Entschlüsselung). |
| Vollständige Pins behauptet | `README.md` | Die Executive Summary verspricht, alle Images & Modelle seien über `VERSIONS.lock` determiniert – für die privaten GHCR-Images fehlen jedoch weiterhin Digests. | Absatz relativieren (Operator-Hinweis oder ToDo) oder Digests liefern. |

## 4. Sicherheit & Privacy — Note: befriedigend
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Unvollständige Digest-Matrix | `.env.example`, `VERSIONS.lock` | OCR/TEI/Reranker bleiben ohne verifizierten Digest. Das untergräbt den Supply-Chain-Gewinn der übrigen Pins. | Zugriff organisieren und `@sha256`-Digests ergänzen; bis dahin deutlicher Risiko-Hinweis in Doku/Secrets-Policy. |

## 5. Funktionalität & Korrektheit — Note: mangelhaft
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Backup/Restore asymmetrisch | `scripts/restore.sh`, `scripts/backup.sh` | `backup.sh` liefert nun nur noch `*.tar.zst.age`; `restore.sh` erwartet weiterhin ein unverschlüsseltes `.tar.zst` und scheitert ohne vorgelagerte Entschlüsselung. | Restore-Skript um `age --decrypt` erweitern oder Runbook um verpflichtenden Entschlüsselungsschritt ergänzen. |

## 6. Outdated / Unreferenced / Undocumented — Note: ausreichend
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Backup-Doku hinkt der Umsetzung hinterher | `RUNBOOK.md` | Die Schrittfolge unter „Backup & Restore Procedures“ erwähnt keinen `age`-Schlüssel oder Empfänger-Konfiguration, obwohl das Script ohne diese Parameter abbricht. | ToDo-/Parameterliste ergänzen (Empfängerdatei/Variablen, Entschlüsselungspfad). |

## 7. Reproduzierbarkeit — Note: ausreichend
| Fundstelle | Artefakt | Problem | Korrektur |
| --- | --- | --- | --- |
| Private Images ohne Hash | `.env.example`, `VERSIONS.lock` | Wie in Run 1 angekündigt, fehlen weiterhin die Digests für OCR/TEI/Reranker – reproduzierbare Builds bleiben dort Glückssache. | Zugriff klären, Digests ziehen, optional CI-Check einbauen. |

## Gesamturteil
- **Gesamtnote:** 2,7 (befriedigend−) – Viele Baustellen aus Run 1 sind geschlossen, die neue Verschlüsselung reißt jedoch eine Restore-Lücke und die privaten Images verhindern weiterhin eine lupenreine Reproduzierbarkeit.

## To-Do (für nächstes Commit)
1. Restore-Workflow auf die verschlüsselten Archive angleichen (`age --decrypt` + Dokumentation).
2. GHCR-Digests für OCR/TEI/Reranker einholen und in `.env.example`/`VERSIONS.lock` einpflegen.
3. README/Runbook auf den realen Backup-Prozess (inkl. `age`-Voraussetzungen) aktualisieren.
4. Basement-Stubs (z. B. `g-ollama`) mit Digests versehen oder deutlicher als nicht-promotionsfähig kennzeichnen.

## Mündlicher Kommentar
> "Sie haben die Log-Baustelle geschlossen und endlich Checksums eingeführt – bravo. Doch wer verschlüsselt, muss auch an die Rückreise denken. Entschlüsseln Sie mir das Restore, pinnen Sie die privaten Container, und dann reden wir über eine Eins." 
