# House Guide

Die House-Metapher gliedert das Repository in fünf Ebenen: Fundament,
Basement, Wardrobe, Entrance und Stable. Jede Ebene besitzt einen klaren
Auftrag, eigene Artefakte und Promotion-Gates. Dieses Dokument beschreibt, wie
sich die Verzeichnisse daran orientieren und welche Regeln für neue Bewohner
(gemeint sind Projekte oder Services) gelten.

## Leitlinien
- **Trennung nach Verantwortlichkeit**: Infrastruktur und Host-Notizen gehören
  ins Fundament, experimentelle Services ins Basement, Verpackungen in die
  Wardrobe, frühe Nutzerkontakte ins Entrance und produktive Pfade ins Stable.
- **Aufstieg nur mit Dokumentation**: Bevor ein Artefakt in eine höhere Ebene
  befördert wird, müssen Zweck, Abhängigkeiten und Teststatus dokumentiert sein
  (siehe Logbuch und Projektdossiers).
- **Toolbox als Referenzbewohner**: Solange keine weiteren Projekte eingezogen
  sind, dient die Toolbox als Blaupause für Struktur, Benennung und Promotion
  Flow.

## Verzeichnis-Zuordnung
| Ebene     | Verzeichnis(e)                    | Status                           |
|-----------|-----------------------------------|----------------------------------|
| Fundament | `fundament/`                      | Baselines & Promotionskelette    |
| Basement  | `basement/`, `basement/toolbox/`  | Aktive Planung & erste Projekte  |
| Wardrobe  | `wardrobe/`                       | Overlay- und Wrapper-Placeholder |
| Entrance  | `entrance/`                       | Canary- & Telemetrie-Stub        |
| Stable    | `stable/`                         | Produktions-Placeholder          |

## Dokumentations-Hooks
- Architekturentscheidungen landen im [Blueprint](blueprint.md).
- Projektspezifika wandern unter `docs/projects/`.
- Tägliche Anpassungen dokumentiert das [Logbuch](../logbook/README.md).
- Querverweise in READMEs sollten auf diese Dokumente zeigen, damit neue
  Mitwirkende den Kontext schnell erfassen.

## Nächste Schritte
1. Promotion-Checklisten pro Ebene ableiten und unter `fundament/` sowie den
   jeweiligen Layern ablegen.
2. Für zukünftige Projekte vorab Dossier-Vorlagen erstellen, die das Toolbox
   Layout wiederverwenden.
3. Wardrobe-Overlays konkretisieren und mit Basement-Compose-Drafts verheiraten,
   sobald die Toolbox ihre Kernaufgaben erfüllt.
