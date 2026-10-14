# LET`SMEETUP

Kalendarz grupowy z synchronizacją w czasie rzeczywistym, trybem offline, grupami z kodami zaproszeń
i „malowaniem” wydarzeń po kalendarzu.

| Część | Technologia | Katalog |
|---|---|---|
| Aplikacja mobilna (Android / iOS) | Flutter 3.44, Riverpod 3, Drift (SQLite), go_router, Dio, Socket.IO | [`app/`](app/) |
| Backend (REST + WebSocket) | Node.js 24, TypeScript, Express 5, Prisma 6, PostgreSQL 17, Socket.IO | [`backend/`](backend/) |
| Analiza dokumentacji i zmiany | — | [`docs/ANALIZA.md`](docs/ANALIZA.md) |

Wszystkie składniki są darmowe i open source. Supabase nie jest używany.

---

## Szybki start (lokalnie)

### 1. Baza danych i poczta testowa

**Z Dockerem** (zalecane):

```bash
docker compose up -d db mail
```

- PostgreSQL: `localhost:5432` (użytkownik/hasło/baza: `letsmeetup`)
- Mailpit (podgląd e-maili z kodami weryfikacyjnymi): http://localhost:8025

**Bez Dockera** — wbudowany PostgreSQL uruchamiany z Node:

```bash
cd backend
npm run db:local        # zostaw otwarte w osobnym terminalu
```

Bez Mailpita w `backend/.env` ustaw puste `SMTP_HOST=` — kody weryfikacyjne pojawią się w logach serwera.

### 2. Backend

```bash
cd backend
npm install
cp .env.example .env    # ustaw JWT_SECRET!
npx prisma migrate deploy
npm run dev             # http://localhost:3000
```

Testy (wymagają działającego PostgreSQL; tworzą bazę `letsmeetup_test`):

```bash
npm test
```

### 3. Aplikacja

```bash
cd app
flutter pub get
dart run build_runner build      # generuje kod Drift (lib/data/local/database.g.dart)
flutter run                      # emulator Androida łączy się z http://10.0.2.2:3000
```

Inny adres serwera (np. telefon w tej samej sieci Wi-Fi albo serwer produkcyjny):

```bash
flutter run --dart-define=API_URL=http://192.168.1.20:3000
```

Testy: `flutter test`

---

## Powiadomienia push (opcjonalnie, darmowe FCM)

Aplikacja i serwer działają bez Firebase — powiadomienia o aktywności grup są wtedy pokazywane,
gdy aplikacja jest otwarta (WebSocket), a przypomnienia o wydarzeniach działają zawsze (lokalnie).

Aby włączyć push w tle:

1. Utwórz projekt w [Firebase Console](https://console.firebase.google.com) (plan Spark — bezpłatny).
2. Aplikacja: `dart pub global activate flutterfire_cli` → w katalogu `app/` uruchom `flutterfire configure`
   (doda `google-services.json` / `GoogleService-Info.plist`). Na iOS włącz Push Notifications w Xcode i wgraj klucz APNs w Firebase.
3. Serwer: Firebase Console → Ustawienia projektu → Konta usługi → „Wygeneruj klucz prywatny”,
   zapisz plik i podaj ścieżkę w `FIREBASE_SERVICE_ACCOUNT_FILE` w `backend/.env`.

---

## Wdrożenie w chmurze (darmowe: Render + Neon + Brevo)

Serwer działa wtedy bez Twojego komputera. Żadna z usług nie wymaga karty płatniczej.

1. **GitHub** — utwórz puste repozytorium (np. `letsmeetup`) i wypchnij kod:
   ```bash
   git remote add origin https://github.com/<login>/letsmeetup.git
   git push -u origin main
   ```
2. **Neon** (https://neon.tech) — utwórz projekt (region: Frankfurt) i skopiuj *connection string*
   (Dashboard → Connect, wersja bez „pooled”), np. `postgresql://user:hasło@ep-xxx.eu-central-1.aws.neon.tech/neondb?sslmode=require`.
3. **Brevo** (https://www.brevo.com) — załóż konto, zweryfikuj adres nadawcy, a w *SMTP & API* wygeneruj klucz SMTP.
   Możesz to pominąć i na start ustawić `REQUIRE_EMAIL_VERIFICATION=false` (rejestracja bez kodu z e-maila).
4. **Render** (https://render.com) → *New → Blueprint* → wybierz repozytorium. Render odczyta [`render.yaml`](render.yaml)
   i poprosi o wartości: `DATABASE_URL` (z Neon), `SMTP_HOST=smtp-relay.brevo.com`, `SMTP_USER`, `SMTP_PASS`,
   `SMTP_FROM` (zweryfikowany nadawca, np. `LETSMEETUP <twoj@adres.pl>`). `JWT_SECRET` wygeneruje się sam.
   Migracje bazy wykonują się automatycznie przy każdym starcie.
5. Sprawdź `https://<nazwa>.onrender.com/health` → `{"ok":true}`.
6. Zbuduj aplikację z adresem serwera:
   ```bash
   cd app
   flutter build apk --release --dart-define=API_URL=https://<nazwa>.onrender.com
   ```

**Ograniczenia planów darmowych:** serwer na Render Free usypia po 15 min bez ruchu, a pierwsze żądanie po przerwie
trwa ok. 1 minuty (aplikacja w tym czasie działa offline i sama się zsynchronizuje). Żeby tego uniknąć, ustaw darmowy
ping co 10 min na `/health` (np. https://cron-job.org) — limit 750 h/mies. wystarcza na jeden serwer działający cały czas.
Neon Free: 0,5 GB danych. Avatary są przechowywane w bazie (Render Free nie ma trwałego dysku).

## API w skrócie

| Metoda | Ścieżka | Opis |
|---|---|---|
| POST | `/auth/register`, `/auth/verify-email`, `/auth/login`, `/auth/refresh`, `/auth/logout` | Konto i sesja (JWT + rotowany refresh token) |
| POST | `/auth/forgot-password`, `/auth/reset-password` | Reset hasła kodem z e-maila |
| GET/PATCH/DELETE | `/me` | Profil, ustawienia, usunięcie konta |
| POST/DELETE | `/me/avatar`, `/me/devices`, `POST /me/password` | Avatar, tokeny push, zmiana hasła |
| GET/POST | `/groups`, `POST /groups/join` | Lista, tworzenie, dołączanie kodem |
| GET/PATCH/DELETE | `/groups/:id` | Szczegóły, edycja (admin), usunięcie z hasłem (admin) |
| POST | `/groups/:id/invite-code`, `/groups/:id/leave` | Nowy kod, opuszczenie grupy |
| PATCH/DELETE | `/groups/:id/members/:userId` | Zmiana roli, usunięcie członka |
| GET/POST/PATCH/DELETE | `/events`, `/events/:id` | Wydarzenia (PATCH = tylko zmienione pola) |
| POST | `/events/batch`, `/events/batch-delete` | Tryb malowania i cofanie |
| PUT/DELETE | `/events/:id/exceptions/:date` | Zmiana/odwołanie pojedynczego wystąpienia serii |
| GET | `/sync?since=…` | Synchronizacja przyrostowa (zmiany + usunięcia) |

WebSocket (Socket.IO, token w `auth.token`): `event:upsert`, `event:delete`, `groups:changed`, `group:removed`.
