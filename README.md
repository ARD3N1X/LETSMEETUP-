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

## Wdrożenie (darmowe opcje)

- **Docker**: `docker compose up -d` uruchamia bazę, Mailpit i API (`backend/Dockerfile` sam stosuje migracje).
- Hosting API z darmowym planem: np. Render, Railway, Fly.io; baza: np. Neon lub dowolny PostgreSQL.
- SMTP: dowolny (np. Brevo — darmowy limit dzienny, Gmail SMTP z hasłem aplikacji).
- Przed produkcją: długi losowy `JWT_SECRET`, HTTPS, własna konfiguracja podpisywania w `app/android/app/build.gradle.kts`.

---

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
