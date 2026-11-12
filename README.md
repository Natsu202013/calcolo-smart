# Calcolo Smart

Calcolatrice Flutter con tastierino standard e scientifico, memoria, cronologia
persistente e temi chiaro/scuro.

- **App ID**: `com.calcolosmart.calculator`
- **Flutter**: 3.35.4 / Dart 3.9.2
- **Piattaforme**: Android, iOS, Web

---

## Struttura del progetto

```
lib/
├── services/calc_engine.dart        Motore matematico (tokenizer → parser → AST)
├── state/calculator_controller.dart Logica input, memoria, cronologia, tema
├── models/history_entry.dart        Modello voce di cronologia
├── screens/
│   ├── calculator_screen.dart       Schermata principale
│   └── history_screen.dart          Cronologia calcoli
├── widgets/
│   ├── calc_display.dart            Display espressione + risultato
│   ├── calc_keypad.dart             Tastierini standard / scientifico
│   └── calc_button.dart             Tasto animato con feedback aptico
└── theme/app_theme.dart             Palette dark/light + ThemeExtension
```

## Sviluppo locale

```bash
flutter pub get
flutter analyze      # deve dire "No issues found!"
flutter test         # 25 test
flutter run -d chrome
```

## Build

| Piattaforma | Comando | Ambiente richiesto |
|---|---|---|
| Web | `flutter build web --release` | qualunque OS |
| Android APK | `flutter build apk --release` | Linux/macOS/Windows + Android SDK |
| Android AAB | `flutter build appbundle --release` | Linux/macOS/Windows + Android SDK |
| **iOS IPA** | `flutter build ipa --release` | **solo macOS + Xcode** |

---

# 📱 Come ottenere l'IPA da GitHub Actions

Il file `.github/workflows/ios-ipa.yml` compila l'app su un **runner macOS** di
GitHub (gratuito per repository pubblici) e produce un `.ipa` scaricabile.
Non serve possedere un Mac.

## Prerequisiti

1. Un account GitHub.
2. Il codice di questo progetto caricato in un repository.

## Passo 1 — Carica il codice su GitHub

### Opzione A — Tramite l'interfaccia web di GitHub (nessun Git installato)

1. Vai su <https://github.com/new>
2. **Repository name**: `calcolo-smart`
3. Scegli **Public** (necessario per usare i runner macOS gratuitamente)
4. **NON** aggiungere README, .gitignore o licenza (il progetto li ha già)
5. Clicca **Create repository**
6. Nella pagina successiva clicca **uploading an existing file**
7. Trascina **tutto il contenuto** della cartella del progetto
   > ⚠️ Importante: trascina il **contenuto**, non la cartella.
   > Devono comparire `lib/`, `ios/`, `pubspec.yaml` e la cartella nascosta
   > `.github/` alla radice del repository.
8. Commit message: `Calcolo Smart - calcolatrice Flutter`
9. **Commit changes**

### Opzione B — Da terminale con Git

```bash
cd percorso/del/progetto

git init
git add -A
git commit -m "Calcolo Smart - calcolatrice Flutter"
git branch -M main

git remote add origin https://github.com/TUO-UTENTE/calcolo-smart.git
git push -u origin main
```

> Se il push chiede credenziali, usa un **Personal Access Token** come password:
> GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
> → Generate new token → spunta lo scope `repo`.

## Passo 2 — Verifica che il workflow sia presente

Nel repository apri la scheda **Actions**. Devi vedere il workflow
**"Build iOS IPA"** nella colonna sinistra.

Se non appare: la cartella `.github/` non è stata caricata (i file che iniziano
con il punto sono nascosti su macOS/Linux — premi `Cmd+Shift+.` per mostrarli
nel Finder). Ricarica `.github/workflows/ios-ipa.yml`.

## Passo 3 — Avvia la build

1. Scheda **Actions**
2. Clicca **Build iOS IPA** nella colonna sinistra
3. Pulsante **Run workflow** (a destra) → **Run workflow**
4. Attendi ~10-15 minuti

La build parte anche automaticamente ad ogni push che modifica `lib/`, `ios/`,
`pubspec.yaml` o il workflow stesso.

## Passo 4 — Scarica l'IPA

1. Scheda **Actions** → clicca sulla run completata (spunta verde ✅)
2. Scorri in fondo fino alla sezione **Artifacts**
3. Scarica **`CalcoloSmart-ipa`** (file `.zip`)
4. Estrai lo zip → ottieni:
   - `CalcoloSmart.ipa` — il pacchetto iOS
   - `CalcoloSmart.app.zip` — bundle `.app` compresso
   - `CalcoloSmart.ipa.sha256` — checksum di verifica

## Passo 5 — Installa l'IPA su iPhone

L'IPA prodotto è **non firmato**, quindi iOS non lo accetta così com'è.
Tre possibilità:

| Metodo | Costo | Durata | Note |
|---|---|---|---|
| **Sideloadly** | gratis | 7 giorni | account Apple gratuito, va rifirmato ogni settimana |
| **AltStore / SideStore** | gratis | 7 giorni | rifirma automatica finché il dispositivo è nella stessa rete |
| **Apple Developer Program** | 99 €/anno | 1 anno | firma propria + TestFlight + App Store |

### Con Sideloadly (più semplice)

1. Installa [Sideloadly](https://sideloadly.io) su Windows o macOS
2. Collega l'iPhone via USB, selezionalo in cima
3. Trascina `CalcoloSmart.ipa` nel campo **IPA**
4. Inserisci il tuo Apple ID
5. Clicca **Start**
6. Sull'iPhone: **Impostazioni → Generali → VPN e gestione dispositivo**
   → seleziona il tuo Apple ID → **Autorizza**
7. Apri l'app. Con iOS 16+ potrebbe servire attivare la **Modalità sviluppatore**
   (Impostazioni → Privacy e sicurezza → Modalità sviluppatore).

> ⚠️ Con un Apple ID gratuito il bundle ID deve essere univoco: se Sideloadly
> segnala un conflitto, cambia `com.calcolosmart.calculator` in qualcosa come
> `com.tuonome.calcolosmart` nel campo apposito di Sideloadly.

---

## 🔧 Personalizzare il workflow

### Firmare l'IPA con un certificato Apple Developer

Aggiungi i secret nel repository (**Settings → Secrets and variables → Actions**):

| Secret | Contenuto |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | certificato `.p12` in base64 (`base64 -i cert.p12`) |
| `P12_PASSWORD` | password del `.p12` |
| `PROVISIONING_PROFILE_BASE64` | profilo `.mobileprovision` in base64 |
| `KEYCHAIN_PASSWORD` | password arbitraria per il keychain temporaneo |

Poi sostituisci lo step 8 con la firma:

```yaml
      - name: Importa certificato
        env:
          CERT: ${{ secrets.BUILD_CERTIFICATE_BASE64 }}
          P12_PASS: ${{ secrets.P12_PASSWORD }}
          PROFILE: ${{ secrets.PROVISIONING_PROFILE_BASE64 }}
          KEYCHAIN_PASS: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          echo "$CERT" | base64 --decode > cert.p12
          echo "$PROFILE" | base64 --decode > profile.mobileprovision
          security create-keychain -p "$KEYCHAIN_PASS" build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "$KEYCHAIN_PASS" build.keychain
          security import cert.p12 -k build.keychain -P "$P12_PASS" -T /usr/bin/codesign
          security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASS" build.keychain
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/

      - name: Build firmata
        run: flutter build ipa --release --export-method ad-hoc
```

Con `--export-method ad-hoc` ottieni un IPA installabile su dispositivi
registrati nel profilo, senza passare da TestFlight.

### Cambiare la versione

Modifica `version: 1.0.0+1` in `pubspec.yaml`. Il workflow la applica
automaticamente a `CFBundleShortVersionString` e `CFBundleVersion`.

---

## 🍎 Alternativa senza Mac né firma: PWA

Per una calcolatrice la Progressive Web App è spesso la scelta migliore —
icona vera, schermo intero, funziona offline, zero scadenza.

1. Apri l'app nel browser **Safari** dell'iPhone
2. Tocca **Condividi** (icona quadrato con freccia)
3. Scorri e tocca **Aggiungi alla schermata Home**

---

## Test

```
flutter test
```

25 test coprono: precedenza operatori, percentuale relativa, trigonometria in
gradi e radianti, logaritmi, radici, moltiplicazione implicita, gestione errori,
formattazione italiana, sequenze di tasti, memoria, cronologia e persistenza.

## Licenza

Progetto privato — `publish_to: 'none'`.
