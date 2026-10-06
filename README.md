[README.md](https://github.com/user-attachments/files/33110160/README.md)
# Budget – Ausgaben im Blick, direkt vom iPhone

Halte die **Aktionstaste** gedrückt, dann öffnet sich Budget und fragt: *„Was hast du gekauft?“* und *„Wie viel hat es gekostet?“*.
So siehst du jederzeit, wofür dein Geld draufgeht und wie viel noch auf dem Konto ist.

**Funktionen**

- Ausgabe in Sekunden eintragen (Aktionstaste, Kurzbefehl oder Button in der App)
- Kontostand: einmal eingeben, danach wird jede Ausgabe automatisch abgezogen
- Kategorien mit Monatszielen (z. B. Essen 200 €), mit Symbolen und Farben wie in den iPhone-Einstellungen
- Hinweis schon *beim Eintragen*, wenn ein Kauf dein Monatsziel überschreitet
- Tagesbudget: „Noch 84 € übrig. Das sind 6,00 € pro Tag“
- Verlauf mit Suche; zum Bearbeiten antippen, zum Löschen nach links wischen
- Merkt sich frühere Einkäufe und wählt die passende Kategorie automatisch aus
- Export als CSV-Tabelle
- Alle Daten bleiben nur auf deinem iPhone

Voraussetzung: iPhone mit Aktionstaste (iPhone 15 Pro oder neuer) und iOS 17 oder neuer.

---

## Schritt 1: Code auf GitHub hochladen (ca. 5 Minuten)

1. Melde dich auf [github.com](https://github.com) an. Ein kostenloses Konto reicht.
2. Klicke oben rechts auf **+** und dann **New repository**.
   - Name: `budget`
   - **Public** ist komplett kostenlos. **Private** geht auch, das Freikontingent reicht für ca. 30–40 Builds im Monat.
   - Klicke auf **Create repository**.
3. Klicke auf der neuen Seite auf **uploading an existing file**.
4. Entpacke die `Budget.zip` auf deinem PC. Öffne den Ordner `Budget` und markiere **alles darin**: `.github`, `Budget`, `project.yml` und `README.md`. Zieh das ins Browserfenster.
5. Unten auf **Commit changes** klicken.

> ⚠️ **Wichtig:** Prüfe danach, ob im Repository ein Ordner `.github` zu sehen ist.
> Falls nicht: Klicke auf **Add file** und dann **Create new file**. Tippe als Namen `.github/workflows/build.yml` ein,
> kopiere den Inhalt der Datei `build.yml` aus dem ZIP hinein und klicke auf **Commit changes**.

## Schritt 2: App von GitHub bauen lassen (ca. 5–10 Minuten, automatisch)

1. Öffne im Repository oben den Reiter **Actions**. Der Build „iPhone-App bauen“ startet von selbst.
   (Falls GitHub fragt, ob Workflows aktiviert werden sollen, bestätige mit **I understand… enable**.)
2. Warte, bis ein **grüner Haken** erscheint.
3. Klicke auf den Durchlauf. Ganz unten unter **Artifacts** findest du **Budget-ipa**. Lade es herunter.
4. Entpacke die heruntergeladene ZIP. Darin liegt **`Budget.ipa`**, das ist deine App.

Wenn ein **rotes X** erscheint, klicke auf den Durchlauf, kopiere die Fehlermeldung und schick sie mir. Ich korrigiere den Code dann.

## Schritt 3: App aufs iPhone installieren (mit Sideloadly, Windows)

1. Installiere **iTunes** und **iCloud** direkt von apple.com, *nicht* aus dem Microsoft Store.
   Sideloadly empfiehlt die Versionen von der Apple-Website.
2. Installiere **Sideloadly** von [sideloadly.io](https://sideloadly.io).
3. Schließ dein iPhone per USB-Kabel an den PC an und tippe auf dem iPhone auf **Vertrauen**.
4. Öffne Sideloadly und zieh die Datei `Budget.ipa` hinein.
5. Gib deine **Apple-ID** (E-Mail) ein und klicke auf **Start**. Gib dein Apple-ID-Passwort und eventuell einen Bestätigungscode ein.
6. Schalte auf dem iPhone den **Entwicklermodus** ein:
   **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus → an**. Danach startet das iPhone neu, dort mit **Aktivieren** bestätigen.
7. Erlaube die App:
   **Einstellungen → Allgemein → VPN & Geräteverwaltung →** tippe auf deine Apple-ID und dann **Vertrauen**.
8. Fertig: Budget liegt auf deinem Home-Bildschirm. 🎉

## Schritt 4: Aktionstaste einrichten

1. Öffne Budget einmal.
2. Gehe zu **Einstellungen → Aktionstaste**, wische zu **Kurzbefehl** und tippe auf **Kurzbefehl auswählen**.
3. Wähle unter **Budget** den Eintrag **„Ausgabe eintragen“**.

Ab jetzt reicht es, die Aktionstaste **gedrückt zu halten**. Budget öffnet sich mit dem Fenster „Neue Ausgabe“.

*Falls Budget dort nicht auftaucht:* Starte das iPhone einmal neu. Oder bau dir den Befehl selbst:
Öffne die Kurzbefehle-App, tippe auf **+**, füge die Aktion **„URL öffnen“** hinzu, trage `budget://add` ein
und wähle diesen Kurzbefehl dann für die Aktionstaste.

---

## ⏱️ Wichtig: die 7-Tage-Regel

Mit einer kostenlosen Apple-ID läuft eine selbst installierte App **nach 7 Tagen ab** und lässt sich dann nicht mehr öffnen.
**Deine Daten bleiben dabei erhalten.** Du installierst die App einfach erneut darüber:

- **Von Hand:** Wiederhole Schritt 3 (Punkte 3–5) etwa einmal pro Woche. Das dauert 1 Minute.
- **Automatisch:** Sideloadly hat eine Option zum automatischen Auffrischen (Automatic refresh). Dafür muss dein PC laufen und das iPhone im selben WLAN sein.
  Aktiviere dazu in iTunes bei deinem iPhone die Option **„Mit diesem iPhone über WLAN synchronisieren“**.

Tipps, damit nichts verloren geht:
- **Lösch die App nie** vom iPhone, sondern installier immer nur darüber.
- Benutze immer **dieselbe Apple-ID** in Sideloadly.
- Exportier ab und zu deine Daten unter **Ziele → Ausgaben exportieren**.

Ohne 7-Tage-Grenze geht es nur mit dem kostenpflichtigen Apple-Developer-Programm (99 €/Jahr).

## Änderungen an der App

Wenn du etwas ändern willst (Farben, Texte, neue Funktionen): Bearbeite die Dateien direkt auf GitHub oder frag mich.
Nach jeder Änderung baut GitHub automatisch eine neue `Budget.ipa`. Installier sie wie in Schritt 3, deine Daten bleiben erhalten.

## Aufbau des Projekts

```
.github/workflows/build.yml   Bauanleitung für GitHub (macOS-Rechner baut die .ipa)
project.yml                   Projektbeschreibung (daraus wird das Xcode-Projekt erzeugt)
Budget/
  BudgetApp.swift             App-Start und Tabs
  Intents.swift               Aktion "Ausgabe eintragen" für Aktionstaste und Kurzbefehle
  Models.swift                Daten: Ausgaben, Kategorien, Kontostand, Speichern
  DashboardView.swift         Übersicht: Kontostand, Monatsbudget, Kategorien
  AddExpenseView.swift        Fenster "Neue Ausgabe"
  HistoryView.swift           Verlauf aller Ausgaben
  GoalsView.swift             Monatsziele, Kategorien bearbeiten, Einstellungen, Export
  Helpers.swift               Euro-Formatierung, Farben, Symbole, Balken
  Assets.xcassets             App-Icon
```
