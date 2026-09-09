# FamilienHub v4.1 – Einrichtung ohne App Store

Diese Version ist bereits für **GitHub Pages + Supabase** vorbereitet.

## Teil 1 – FamilienHub kostenlos online stellen

### 1. GitHub-Konto
Erstelle ein kostenloses GitHub-Konto, falls du noch keines hast.

### 2. Repository erstellen
Erstelle ein neues Repository, zum Beispiel:

`familienhub`

Für GitHub Free sollte es **öffentlich** sein, wenn du GitHub Pages kostenlos nutzen möchtest.  
Die App selbst kann trotzdem einen Login verlangen; sensible Daten gehören nicht direkt ins Repository.

### 3. Dateien hochladen
Lade **den gesamten Inhalt dieses Ordners** in das Repository hoch – inklusive:

- `.github/workflows/pages.yml`
- `index.html`
- `manifest.webmanifest`
- `sw.js`
- `icons/`
- `supabase/`

### 4. GitHub Pages aktivieren
Öffne im Repository:

**Settings → Pages**

und wähle bei **Source / Build and deployment**:

**GitHub Actions**

Danach läuft der mitgelieferte Workflow automatisch.  
Unter **Actions** kannst du den Status sehen.

### 5. Webadresse öffnen
Nach erfolgreichem Deployment zeigt GitHub eine Adresse ähnlich:

`https://DEIN-NAME.github.io/familienhub/`

Diese Adresse auf dem iPhone in **Safari** öffnen.

### 6. Auf dem iPhone installieren
In Safari:

**Teilen → Zum Home-Bildschirm → Hinzufügen**

Danach erscheint FamilienHub mit eigenem App-Icon und öffnet sich im Standalone-Modus.

---

# Teil 2 – Supabase für mehrere iPhones

## 1. Supabase-Projekt
Erstelle bei Supabase ein kostenloses Projekt.

## 2. Datenbank einrichten
Öffne im Supabase-Dashboard den **SQL Editor**.

Kopiere den kompletten Inhalt von:

`supabase/Supabase_Setup.sql`

hinein und führe ihn einmal aus.

## 3. URL und Publishable Key
Öffne im Projekt den **Connect**-Dialog oder **Settings → API Keys**.

Du benötigst:

- **Project URL**
- **Publishable Key** (`sb_publishable_...`)

Der Publishable Key ist für Browser-/Client-Apps gedacht.  
**Niemals einen Secret Key / service_role Key in FamilienHub eintragen oder an andere weitergeben.**

## 4. FamilienHub verbinden
In FamilienHub:

**Mehr → Familien-Synchronisierung**

Dort Project URL und Publishable Key eintragen.

Danach:

1. Konto erstellen
2. anmelden
3. eine Person legt die Familie an
4. Einladungscode an die übrigen Familienmitglieder weitergeben
5. die anderen treten mit eigenem Konto bei

## 5. Test
Zum Test:

- auf iPhone A einen Termin erstellen
- einige Sekunden warten
- auf iPhone B FamilienHub öffnen
- der Termin sollte dort ebenfalls erscheinen

Die aktuelle Cloud-Synchronisierung prüft regelmäßig auf Änderungen und verwendet vorerst
**„letzte Änderung gewinnt“** als Konfliktregel.

---

# Sicherheit

In das GitHub-Repository gehören **nicht**:

- Supabase Secret Key
- service_role Key
- Home-Assistant Long-Lived Access Token
- Passwörter

Der Supabase **Publishable Key** ist für Client-Anwendungen vorgesehen; die eigentliche
Zugriffskontrolle erfolgt über die in `Supabase_Setup.sql` eingerichteten Row-Level-Security-Regeln.

Der Home-Assistant-Token wird in der aktuellen Browser-Demo lokal im Browser gespeichert.
Für eine spätere native iOS-App sollte er im iOS Keychain gespeichert werden.
