# MAD Location Tracker

Modularbeit im Rahmen des Moduls Mobile App Development im Frühlingssemester 2024.

## Lokales Setup

### Versionsanforderungen
- Flutter: ?
- Android: ?

### Firebase Authentication
Um die Firebase Authentication in Android nutzen zu können, muss zuerst der SHA-1 und der SHA-256 Fingerprint im **[Firebase Projekt](https://console.firebase.google.com/project/mad-location-tracker/settings/general/android:com.example.mad_location_tracker)** hinterlegt werden.

Nachdem die Fingerprints hinzugefügt wurden, muss das neue google-services.json heruntergeladen und im Projekt im Ordner *android\app* abgelegt werden (falls bereits ein solches File vorhanden ist, muss dieses ersetzt werden).

### Projekt starten

Nachdem der vorherige Schritt abgeschlossen wurde, kann das Projekt nun im
Android Studio gestartet werden.
Hierfür kann entweder ein physisches oder ein emuliertes Android-Gerät verwendet
werden (insofern USB-Debugging auf dem physischen Gerät aktiviert wurde).


## Benutzung

1. Melden Sie sich mit einem Google-Konto an.

> [!WARNING]  
> Die Verwendung eines Google Workspace Accounts führt momentan zu Problemen und
> wird somit aktuell nicht unterstützt.

2. Klicken Sie den Knopf `+ Activity` und geben Sie anschliessend den Titel der
   Aktivität ein, welche Sie tracken möchten.

3. Anschliessend öffnet sich die Kartenansicht, in welcher die getrackte Location
   ersichtlich ist und mitverfolgt werden kann.

4. Nach Abschluss der Aktivität kann unten auf den Knopf `Finish Activity` geklickt
   werden, um die Aufnahme der Location zu beenden.

Abgeschlossene Aktivitäten können im Nachhinein via Listenansicht erreicht und
angeschaut werden.
