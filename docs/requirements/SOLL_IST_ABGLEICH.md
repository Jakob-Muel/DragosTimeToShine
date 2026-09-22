# DraGO – Soll-Ist-Abgleich

Stand: 22.09.2026. Grundlage: [Originalbericht](DRAGO_PRODUKTANFORDERUNGEN_UND_IMPLEMENTIERUNGSPLAN.html).
Bewertet anhand des Quellcodes und der lokalen Tests, nicht anhand eines neuen iPhone-Gerätetests. Die Prozentbereiche im Bericht sind Planungsphasen, keine gemessene Fertigstellung.

| Bereich des Berichts | Stand im Prototyp | Bewertung |
| --- | --- | --- |
| Lokal/offline, keine Konten | Lokaler Spielstand; kein Backend für den Kernablauf notwendig | Grundprinzip vorhanden; vollständige Flugmodus-Abnahme auf iPhone noch offen |
| Individuelle Seed-Drachen | Gespeicherter Aussehens-Seed, prozedurale Ansichten für Pflege, Flug und Elementtraining | Teilweise: kein vollständiges Genom, keine Generatorversion/Genom-Snapshots |
| Freie Drachenpopulation | Zufällige Auswahl aus fünf festen Basistypen; mehrere Individuen je Typ; Kapazität 12 | Abweichung: weiterhin fester Katalog, keine praktisch unbegrenzte Zuchtpopulation |
| Genetische Zucht | Wählbare Vererbung der drei Attributpotenziale, Eltern-IDs und Generationen; Eltern bleiben erhalten | Attributvererbung vorhanden; grafische/elementare Vererbung, Mutationen und Stammbaumansicht fehlen |
| Ei-Lebenszyklus | Ein generisches Ei, verborgenes Ergebnis und Aussehens-Seed bei Vergabe festgelegt, Starter sofort, Käufe 5.000 Schritte | Aktuelle Nutzerentscheidung umgesetzt; Seltenheits-/Aufgabenstufen aus Bericht fehlen bewusst noch |
| HealthKit | Nativer iOS-Provider mit lesendem Zugriff und Berechtigungsablauf vorhanden | Integration vorhanden; aktuelle Gerätetests und Sonderfallprüfung offen |
| Schrittzuweisung / Ledger | Fortschritt je Ei seit Brutbeginn | Zuweisung, Aufteilung und gemeinsames Ledger gegen Mehrfachverwendung fehlen |
| Training | Flugparcours und Element-Minispiel; getrennte XP, Rekorde, Sterne, Pflegebonus | Zwei von vier Trainingsarten; Stärke durch Schritte und Intelligenz-Turm fehlen |
| Attribute / Level | Drei individuell trainierbare Werte mit festen Potenzialen und Kategorienlevel vorhanden; Minispieltempo und Trefferwirkung weiter fest | Kampfwerte gespeichert und trainierbar; Kampfwirkung, Fähigkeiten, Entwicklungsstufen und Gesamtlevel fehlen |
| Aufholsystem | Kein Levelstein-Inventar | Fehlt |
| Kampf | Flugwettbewerbe mit Distanzzielen und Gold | Rundenbasierter 1-gegen-1-Kampf, Status, Resistenzen und Taktik fehlen |
| Adaptive Offline-Ladder | Keine persistente Folge adaptiver KI-Kampfgegner | Fehlt |
| Belohnungen | Gold für Eier, Fusion Stars für feste Fusionen | Elementar-/Levelsteine und Kampfrewards fehlen |
| Sammlung | Drachenliste, Eierliste und Pflegeansichten | Lexikon, genetische Seltenheit, Stammbaum und Entdeckungen fehlen |
| Speicherintegrität | JSON-Spielstand, Schemaversionen und Migrationen; Trainingsruns gegen doppelte Vergabe geschützt | Atomare Speicherung, Backups, Prüfsummen und umfassende Transaktionen fehlen |
| Technischer Stack | Godot/GDScript mit nativen Schritt-Plugins | Abweichung zu SwiftUI/SpriteKit/SwiftData; kein Wechsel durchgeführt |
| Barrierefreiheit | Responsive Ansichten, Deutsch/Englisch, Text-/Symbolhinweise | Dynamic Type, reduzierte Bewegung, anpassbares Spieltempo und echte alternative Schrittprogression noch nicht vollständig vorhanden |
| Qualitätssicherung | Domain-, Training-, Routing-, Seed- und Gameplay-Tests vorhanden | Keine Tests für noch fehlende Genetik, Ledger, Kampf oder Ladder; vollständige iPhone-Abnahme offen |

## Entscheidungen gegenüber dem Original

1. **Einstieg:** Aktuell ein kostenloses Zufallsei statt der zwei Ausgangsdrachen im Vertical-Slice-Plan.
2. **Eier:** Eine sichtbare Sorte und 5.000 Schritte statt mehrerer Seltenheitsstufen. Bestehende Eier behalten Fortschritt und verborgenes Ergebnis. Fusionen behalten vorläufig ihr festes Ergebnis, verwenden aber dieselbe Ei-Darstellung.
3. **Ökonomie:** Gold-Shop ist aktuell ausdrücklich gewünscht. Der Bericht setzt zusätzlich auf Zucht und Elementar-/Levelsteine; deren Zusammenspiel muss noch entschieden werden.
4. **Sammlung:** Die Begrenzung auf einen Drachen pro Typ widerspricht dem Ziel einer genetischen Population. Das muss beim neuen Datenmodell aufgehoben oder neu definiert werden.
5. **Technologie:** Godot kann die Grundlage bleiben; ob die native Swift-Vorgabe verbindlich ist, ist eine Produktentscheidung. Kein automatischer Neuaufbau.

## Vorgeschlagene Reihenfolge

1. **Drachenmodell und Speichersicherheit:** Individuelle ID, versionierter Seed/Genom-Snapshot, vier trainierbare Attribute und abgeleitete Kampfwerte; atomare Speicherung und Migration. Population nicht mehr allein über Elementtypen identifizieren.
2. **Eier und Zucht darauf aufbauen:** Nachkommen bei Vergabe festschreiben; Eltern, Generation und einfache Vererbung speichern. Gold-Eier liefern Ausgangsdrachen, Zucht liefert Nachkommen – als Vorschlag zu besprechen.
3. **Schritt-Ledger:** Schritte einmal erfassen und gezielt für Ei oder Stärke verbrauchen; Alternative ohne HealthKit gestalten.
4. **Einen vollständigen Kampfablauf bauen:** Ein Drache gegen einen festgeschriebenen KI-Gegner, Attribute wirken sichtbar, Belohnung wird sicher gespeichert.
5. **MVP vervollständigen:** Intelligenz-Minispiel, adaptive Ladder, Steine/Aufholen, Lexikon/Stammbaum, danach Balancing und Gerätetests.

Nächster sinnvoller Umsetzungsschritt ist das Drachen-Datenmodell, nicht weitere kosmetische Element-Eier oder zusätzliche Shop-Einstiege. Dieser Vorschlag ist noch kein Auftrag zur Umsetzung aller Berichtspunkte.

## Ergänzung: bestätigte Attributregeln

Angriffskraft, Angriffsgeschwindigkeit und Bewegungsgeschwindigkeit besitzen je ein
individuelles Potenzial. Fusion übernimmt pro Attribut die vom Spieler gewählte
Eltern-Obergrenze. Jeder Nachkomme muss selbst trainiert werden; Trainingswerte werden
niemals vererbt. Neue Gold-Eier bringen neue Potenziale in die Population. Diese Regeln
sind umgesetzt und ersetzen die frühere Beschränkung auf einen Drachen pro Typ.
Die oben vorgeschlagene Reihenfolge ist entsprechend teilweise begonnen; vollständige
Genetik und Kampfanbindung bleiben offen.
