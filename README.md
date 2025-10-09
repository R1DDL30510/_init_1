# Secure Home Systems (SHS) Bootstrap Stack

> "Secure the house, illuminate the library, promote with confidence."

## 1. Worum es geht
SHS ist ein Technikpaket für Unternehmen, das komplett auf einem eigenen Rechner läuft. Es beantwortet Fragen, indem es zuerst lokale Dokumente durchsucht und danach eine Antwort schreibt. Fachlich nennt man das einen **RAG-Ansatz**: *R*etrieval (*nachschlagen*), *A*ugmented (*mit zusätzlichen Fakten angereichert*), *G*eneration (*Antwort formulieren*). Alles passiert offline und ohne Cloud.

Damit die Daten sicher bleiben, erzwingen wir bei jeder Verbindung **TLS** (Transport Layer Security). Du kannst dir TLS wie einen Briefumschlag vorstellen: Wer keine passende Schlüssel-Kombination besitzt, kann nicht mitlesen oder etwas verändern. "Pipeline" bedeutet hier einfach die Abfolge von Schritten, die vom Eingang einer Frage bis zur fertigen Antwort durchlaufen wird.

Die wichtigsten Programme, die zusammen mit Docker Compose gestartet werden, sind:

| Dienst | Was er tut |
| --- | --- |
| **Proxy** | Lenkt den gesamten Verkehr über verschlüsselte Verbindungen und blockiert alles Unsichere. |
| **OpenWebUI** | Grafische Oberfläche, um Fragen zu stellen und Antworten zu lesen. |
| **n8n** | Automatisierte Arbeitsabläufe, z. B. zum Import neuer Dokumente. |
| **Postgres mit pgvector** | Datenbank, die Texte speichert und sie für schnelle Ähnlichkeitssuche vorbereitet. |
| **MinIO** | Lokaler Dateispeicher für größere Dateien wie PDFs. |
| **OCR & TEI** | Verarbeiten gescannte Dokumente zu durchsuchbarem Text. |
| **Reranker** | Sortiert gefundene Texte nach Relevanz. |
| **Ollama (optional)** | Lokaler KI-Dienst, der die eigentlichen Antworten formuliert, falls GPU-Unterstützung vorhanden ist. |

Alle Docker-Images sind in `VERSIONS.lock` festgehalten. Dadurch wissen wir jederzeit, welche Version eingesetzt wurde. `make`-Befehle erstellen zusätzlich verschlüsselte Backups mit `age`, damit niemand unbefugt Einsicht erhält.

### Sicherheits- und Compliance-Überblick
- **Arbeitsprinzipien:** Lokal arbeiten, nur so viele Rechte wie nötig vergeben, jede Version festhalten, Abläufe protokollieren und bei Fehlern sicher abschalten.
- **Prüfmatrix:** [`docs/audit-matrix.md`](docs/audit-matrix.md) zeigt, wie gut wir diese Prinzipien derzeit einhalten. Letztes Update laut Git-Historie: 2. Oktober 2025. Die Matrix wird mindestens einmal pro Quartal in den Wartungs-Meetings überprüft.

## 2. Orientierung & wichtige Unterlagen
- **Einstieg:** [`docs/project-compendium.md`](docs/project-compendium.md) – Überblick über alle Bereiche des "Hauses" und passende Ansprechpartner.
- **Repository-Karte:** [`docs/repository-map.md`](docs/repository-map.md) – vollständige Pfadübersicht inklusive Validierungs- und Automationshinweisen.
- **Audit-Vorbereitung:** [`docs/pre-release-audit.md`](docs/pre-release-audit.md) – Checkliste, bevor neue Funktionen für externe Tests freigeschaltet werden.
- **Governance:** [`docs/house-governance.md`](docs/house-governance.md) – Wer entscheidet was, welche Abhängigkeiten es gibt und wie Freigaben dokumentiert werden.
- **Zitate & Hinweise:** Überall in der Dokumentation helfen kurze Randbemerkungen dabei, die gemeinsame Sprache beizubehalten.

## 3. Verzeichnisführung ("Hausplan")
Die untenstehende Tabelle fasst die wichtigsten Layer kurz zusammen. Für eine vollständige, gepflegte Zuordnung jedes Ordners – inklusive Validierungs-Skripten, Lockfile-Quellen und Prüfpfaden – siehe die Repository-Karte in [`docs/repository-map.md`](docs/repository-map.md).
| Bereich | Ordner | Zweck | Mehr dazu |
| --- | --- | --- | --- |
| Fundament | [`fundament/`](fundament/) | Basiseinstellungen für das Wirtssystem, z. B. Docker-Vorgaben. | [`docs/architecture.md`](docs/architecture.md) |
| Basement | [`basement/`](basement/) | Sammlung von Dienst-Vorlagen, Schemas und Compose-Entwürfen. | [`docs/revision-2025-09-28.md`](docs/revision-2025-09-28.md) |
| Wardrobe | [`wardrobe/`](wardrobe/) | Profile für verschiedene Hardware (CPU, GPU) und Zusatzwerkzeuge wie `gcodex`. | [`docs/architecture.md`](docs/architecture.md) |
| Entrance | [`entrance/`](entrance/) | Testbereich mit Messpunkten, bevor etwas produktiv geht. | [`docs/revision-2025-09-28.md`](docs/revision-2025-09-28.md) |
| Stable | [`stable/`](stable/) | Grundgerüst für den späteren Produktivbetrieb. | [`docs/revision-2025-09-28.md`](docs/revision-2025-09-28.md) |
| Operations | [`scripts/`](scripts/) | Hilfsskripte für TLS, Backups, Status und Tests. | [`RUNBOOK.md`](RUNBOOK.md) |
| Plattform | [`compose.yaml`](compose.yaml) | Docker-Startplan mit Profilen für Minimal- und GPU-Betrieb. | [`SECURITY.md`](SECURITY.md) |
| Daten | [`db/`](db/) | Datenbankschema, Sicherheitsregeln und Rollen. | [`SECURITY.md`](SECURITY.md) |
| Tests | [`tests/`](tests/) | Automatisierte Akzeptanztests mit Protokollen. | [`RUNBOOK.md`](RUNBOOK.md) |

## 4. Dokumentensammlung
- [`docs/project-compendium.md`](docs/project-compendium.md): Navigationshilfe durch alle Ebenen des Hauses, inklusive Zielgruppen.
- [`RUNBOOK.md`](RUNBOOK.md): Schritt-für-Schritt-Anleitungen für Betrieb, Wartung und Notfälle.
- [`SECURITY.md`](SECURITY.md): Sicherheitsmodell, Risiken und Gegenmaßnahmen – in Alltagssprache beschrieben.
- [`docs/architecture.md`](docs/architecture.md): Bildet die Haus-Metapher ab und erklärt geplante Weiterentwicklungen.
- [`docs/revision-2025-09-28.md`](docs/revision-2025-09-28.md): Aufgabenliste pro Bereich, inklusive Anmerkungen zu anstehenden Freigaben.
- [`docs/audit-matrix.md`](docs/audit-matrix.md): Bewertet den Status wichtiger Kontrollen, inklusive nächster Schritte.
- [`docs/pre-release-audit.md`](docs/pre-release-audit.md): Prüfbericht mit offenen Punkten, bevor Funktionen den Testbereich verlassen.
- [`docs/house-governance.md`](docs/house-governance.md): Dokumentiert Verantwortliche und Freigaben.
- [`docs/stack-plan-review.md`](docs/stack-plan-review.md): Ordnet externe Vorschläge zum Image-Pinning in die bestehende SHS-Dokumentation ein.
- [`docs/runbook-ga-02-delete-playbook.md`](docs/runbook-ga-02-delete-playbook.md): Vorlage für zukünftige Löschübungen.

## 5. Betrieb in einfachen Schritten
1. **Arbeitsordner prüfen:** Stelle sicher, dass das Repository an einem Pfad liegt, den `scripts/validate_workspace.sh` akzeptiert.
2. **Umgebungsdatei vorbereiten:**
   ```bash
   cp .env.example .env.local
   sed -i 's/***FILL***/<dein-wert>/g' .env.local
   ```
3. **Grundschutz erzeugen:**
   ```bash
   make bootstrap
   ```
   Dieser Befehl legt Ordner an, erstellt Zertifikate und aktiviert Schutzschalter.
4. **Versionen kontrollieren:** Passe `VERSIONS.lock` an, falls neue Container benötigt werden.
5. **Dienste starten (Standardprofil):**
   ```bash
   make up
   ```
6. **Status prüfen:**
   ```bash
   make status
   ```

### Profile
- **minimal:** Läuft komplett auf CPU und verzichtet auf Ollama. Ideal zum Testen.
- **gpu:** Aktiviert Ollama und nutzt NVIDIA-Grafikkarten. Starten mit:
  ```bash
  docker compose --env-file .env.local --profile gpu up -d
  ```

### Toolbox & `gcodex`
- `basement/toolbox/docker-compose.draft.yml` stellt eine abgeschottete Umgebung zum Experimentieren bereit.
- Sobald `ollama serve` auf dem Host läuft, kann folgende Hilfe genutzt werden:
  ```bash
  ./basement/toolbox/bin/gcodex
  ```
- Zusätzliche Flags werden direkt an die Codex-CLI durchgereicht, z. B. `./basement/toolbox/bin/gcodex --version`.
- Falls der Entwurf fehlt, erklärt das Skript Alternativen. Mehr dazu in [`basement/toolbox/README.md`](basement/toolbox/README.md).

### Wichtige Umgebungsvariablen
- `SHS_BASE`, `SHS_DOMAIN`, `TLS_MODE`, `WATCH_PATH`, `LAN_ALLOWLIST`, `OFFLINE` – Grundkonfiguration für die Umgebung.
- `POSTGRES_*`, `MINIO_*`, `N8N_*`, `OPENWEBUI_*` – Zugangsdaten zu den einzelnen Diensten.
- `*_IMAGE` – Verweis auf die verwendeten Docker-Images.
- `BACKUP_AGE_RECIPIENTS(_FILE)` und `BACKUP_AGE_IDENTITIES(_FILE)` – Schlüssel für verschlüsselte Backups.

### TLS & Geheimnisse einfach erklärt
- `make bootstrap` ruft `scripts/tls/gen_local_ca.sh` auf. Dadurch entsteht eine lokale Zertifizierungsstelle (`secrets/tls/ca.crt`) und ein Zertifikat für die Dienste (`secrets/tls/leaf.pem`).
- `make ca.rotate` erneuert diese Zertifikate. Wenn sie fehlen, starten die Dienste bewusst nicht.
- Alle sensiblen Dateien liegen in `secrets/` oder `.env.local` und sind von Git ausgeschlossen.

### Beobachtung & Nachvollziehbarkeit
- Protokolle liegen als JSON-Zeilen in `logs/shs.jsonl` und enthalten eindeutige `trace_id`s.
- `scripts/status.sh` fasst erreichbare HTTPS-Endpunkte, aktive Profile und Versionsstände zusammen.
- Die Tests im Ordner `tests/acceptance/` dokumentieren jeden Lauf inklusive Rückgabewert und `trace_id`.

### Datenmodell & Arbeitsabläufe
- `db/schema.sql` beschreibt Tabellen für Dokumente, Textstücke und Vektor-Indizes.
- `db/policies.sql` regelt, welche Rolle was lesen oder schreiben darf.
- `n8n/init_flows.json` enthält vorbereitete Abläufe für Import, Synchronisation und Wiederherstellung.

## 6. Tests
Führe die komplette Testsuite aus, sobald alle Dienste bereitstehen:
```bash
make test
```
Die Skripte unter `tests/acceptance/` prüfen verschlüsselten Zugriff, wiederholbare Importe, Antworten mit Quellen, Datenbankabfragen, Synchronisation und Fehlerszenarien.

## 7. Änderungen & Ausblick
- **Doppelte Inhalte reduzieren:** `docs/architecture.md` und `docs/revision-2025-09-28.md` überschneiden sich bewusst. Sobald der Tagesbetrieb stabil läuft, werden beide zu einem gemeinsamen Dokument zusammengeführt.
- **Runbooks erweitern:** `RUNBOOK.md` bleibt das Hauptdokument für Abläufe. Ausführliche Hintergründe landen hier im README oder in der Audit-Matrix.
- **Sicherheitsquelle bündeln:** `SECURITY.md` bleibt die einzige verbindliche Liste aller Sicherheitsmaßnahmen.
- **Platzhalterbereiche beobachten:** `wardrobe/`, `entrance/` und `stable/` dienen aktuell der Planung. Einmal pro Quartal prüfen wir, ob daraus aktive Komponenten werden.

## 8. Beitrag leisten
- YAML-Dateien mit zwei Leerzeichen einrücken, Markdown-Codeblöcke mit vier Leerzeichen.
- Änderungen an Architektur oder Betrieb immer zuerst in der Dokumentation festhalten, dann Code anpassen.
- Commit-Nachrichten im Imperativ verfassen, z. B. `Aktualisiere Basement-Dokumentation`.
- Keine Geheimnisse committen. Neue Abhängigkeiten gehören vor einer Veröffentlichung nach `fundament/versions.yaml` oder `basement/toolbox/inventories/`.
