# LET`SMEETUP — analiza dokumentacji i zmiany względem wersji 1.0

Ten plik opisuje błędy i niespójności znalezione w `dokumentacja_kalendarz_grupowy.md`,
nowy stos technologiczny (bez Supabase) oraz decyzje UX podjęte przy porządkowaniu prototypów.

---

## 1. Nowy stos technologiczny

| Obszar | Było (dokumentacja) | Jest (LET`SMEETUP) | Dlaczego |
|---|---|---|---|
| Backend | Supabase (BaaS) | **Node.js 24 + TypeScript + Express 5** | Najpopularniejszy darmowy stos backendowy, brak vendor lock-in, pełna kontrola nad logiką biznesową. |
| Baza danych | Supabase PostgreSQL | **PostgreSQL 17** (Docker) | Ta sama relacyjna baza, ale własna instancja — darmowa, przenośna na dowolny hosting. |
| ORM / migracje | SQL + RLS | **Prisma 6** | Typowane zapytania, migracje w repozytorium. |
| Autoryzacja | Supabase Auth + RLS | **JWT (access 15 min) + rotowane refresh tokeny**, hasła **bcrypt** | Uprawnienia sprawdzane w kodzie serwera (warstwa `permissions.ts`) — łatwiej testować niż polityki RLS. |
| Realtime | Supabase Realtime | **Socket.IO** (pokoje `user:<id>` i `group:<id>`) | Najpopularniejsza biblioteka WebSocket, automatyczny reconnect. |
| Funkcje serwerowe | Edge Functions (Deno) | Zwykłe moduły serwera | Jedna baza kodu, brak osobnego runtime. |
| E-mail | Supabase default | **Nodemailer + SMTP** (lokalnie **Mailpit**) | Dowolny darmowy SMTP (np. Brevo, Gmail SMTP). |
| Pliki (avatary) | Supabase Storage | Dysk serwera + **sharp** (resize do 256 px WebP) | Darmowe, bez zewnętrznych usług. |
| Push | FCM | **FCM (firebase-admin)** — opcjonalne | FCM jest darmowe; serwer działa także bez skonfigurowanego Firebase. |
| Walidacja | „Edge Functions” | **Zod** | Jeden schemat = walidacja + typy. |
| Rate limiting | — | **express-rate-limit** | Logowanie, rejestracja, kody zaproszeń (10/min). |
| Testy backendu | — | **Vitest + Supertest** | |

### Frontend — korekty bibliotek
| Było | Jest | Powód |
|---|---|---|
| Hive (cache ustawień) | **shared_preferences** | Hive 2.x nie jest już rozwijany; trzy lokalne magazyny (Drift + Hive + secure storage) to o jeden za dużo. |
| Retrofit | sam **Dio** | Retrofit dodaje generowanie kodu bez realnej korzyści przy ~25 endpointach. |
| syncfusion_flutter_datepicker | wbudowane `showDatePicker` / `showTimePicker` | Syncfusion ma licencję komercyjną (Community License z ograniczeniami) — nie jest „darmowe” w każdym przypadku. |
| flex_color_picker | stała paleta 16 kolorów | Prototyp i dokumentacja i tak zakładają 16 predefiniowanych kolorów. |
| supabase_flutter | **socket_io_client** + Dio | Wymiana backendu. |
| Riverpod 2 + generator | **Riverpod 3** (bez generatora) | Aktualna wersja; mniej generowanego kodu (generator potrzebny tylko dla Drift). |

---

## 2. Błędy i niespójności w dokumentacji (oraz jak je rozwiązano)

### Model danych
1. **`end_date = NULL` oznacza „całodniowe”, a jednocześnie istnieje `is_all_day`.** Dwa źródła prawdy dla tej samej informacji. → Całodniowość określa wyłącznie `allDay`; `endAt` jest opcjonalne zawsze.
2. **Wydarzenia całodniowe zapisane jako `timestamptz` w UTC** przesuwają się o dzień u użytkowników w innych strefach (np. 2026-08-14 00:00 w Warszawie = 2026-08-13 22:00 UTC). → Dla `allDay` data jest traktowana jako data kalendarzowa (północ UTC = „ten dzień”), bez konwersji strefy.
3. **`by_week_day: 0=pon … 6=ndz`** — niezgodne z Dartem (`DateTime.weekday`: 1=pon … 7=ndz) i z RFC 5545. → Używamy ISO: 1=pon … 7=ndz.
4. **Dwa mechanizmy powtarzalności naraz**: `recurrence_parent_id` (instancje jako osobne wiersze) oraz `event_instances` (master + wyjątki). → Zostaje tylko master + tabela wyjątków `event_exceptions` (override/odwołanie pojedynczego wystąpienia). Pole `is_cancelled` było używane w regułach (7.4), ale brakowało go w encji z sekcji 4.1.
5. **Brak kolumn, do których odwołuje się dokumentacja:** `profiles.fcm_token` (notatka 6, Edge Function), `language`, ustawienia przypomnień, kolor grupy (sekcje 5.2 i 6.5 mówią o „kolorze identyfikacyjnym grupy”, ale tabela `groups` go nie ma). → Dodane: `groups.color`, `users.language`, `users.remindersEnabled`, `users.defaultReminderMinutes`, `users.accentColor`.
6. **Jeden `fcm_token` na profil** — użytkownik z telefonem i tabletem dostawałby push tylko na jedno urządzenie. → Osobna tabela `device_tokens` (wiele urządzeń, czyszczenie nieważnych tokenów).
7. **`events.group_id ON DELETE SET NULL`** — po usunięciu grupy jej wydarzenia stają się „prywatnymi” wydarzeniami autorów (niespodziewanie pojawiają się w ich kalendarzu). → `ON DELETE CASCADE`.
8. **ID generowane po stronie serwera (`gen_random_uuid()`) przy architekturze offline-first** — wydarzenie utworzone offline nie ma ID, więc nie da się go potem edytować/usunąć przed synchronizacją. → UUID generuje klient; serwer akceptuje je idempotentnie (ponowiony request nie tworzy duplikatu).
9. **Brak informacji o usunięciach dla synchronizacji przyrostowej.** Klient, który był offline, nigdy się nie dowie, że wydarzenie usunięto (realtime DELETE dociera tylko do podłączonych). → Tabela `event_tombstones` + endpoint `GET /sync?since=…`.
10. **Nowo dołączony członek nie dostałby starszych wydarzeń grupy** przy synchronizacji „zmienione od czasu X”. → Sync dołącza pełną listę wydarzeń grup, do których dołączono po `since`.

### Bezpieczeństwo (szkice RLS)
11. **INSERT na `events` sprawdza tylko `created_by = auth.uid()`** — każdy mógłby dodać wydarzenie do cudzej grupy, znając jej UUID. → Serwer wymaga członkostwa w grupie docelowej (także przy przenoszeniu wydarzenia do innej grupy w UPDATE).
12. **„Dodawanie do `group_members` przez invite code” nie da się wyrazić w RLS** — w praktyce polityka musiałaby pozwolić na INSERT samego siebie do dowolnej grupy (także z rolą `admin`). → Dołączanie tylko przez endpoint `POST /groups/join` z kodem; rola zawsze `member`.
13. **Grupę może czytać tylko członek**, więc nie da się wyszukać grupy po kodzie zaproszenia przed dołączeniem. → Rozwiązane endpointem serwerowym (jw.).
14. **Polityka SELECT na `profiles` odwołuje się do `group_members`, którego polityki odwołują się do członkostwa** — klasyczna rekurencja RLS w Supabase („infinite recursion detected in policy”). → Nie dotyczy (brak RLS), widoczność profili liczona w zapytaniu.
15. **Brak reguły „ostatni admin”** przy zmianie ról — admin mógł zdegradować sam siebie i zostawić grupę bez admina (wbrew 7.2). → Serwer blokuje degradację/opuszczenie przez ostatniego admina, jeśli w grupie są inni członkowie.
16. **Limity 100 członków / 20 grup** opisane w 7.2, ale nigdzie nie egzekwowane. → Egzekwowane na serwerze (konfigurowalne w `.env`).

### Synchronizacja i konflikty
17. **Last-write-wins na podstawie `updated_at` z zegara klienta** — rozjechane zegary urządzeń decydują o wyniku. → Kolejność ustala serwer; każdy rekord ma `version` nadawany przez serwer.
18. **Nadpisywanie całego rekordu (11.3)** gubi równoległe zmiany różnych pól. → `PATCH` wysyła tylko zmienione pola (field-level LWW) — scenariusz „A zmienia tytuł, B kolor” daje oba efekty.
19. **Filtr realtime `group_id=in.(…)` nie obejmuje wydarzeń prywatnych** (`group_id IS NULL`) — zmiana prywatnego wydarzenia na telefonie nie dotarłaby na tablet. Lista grup w filtrze jest też zamrożona w chwili subskrypcji. → Pokoje Socket.IO `user:<id>` (prywatne) + `group:<id>`; serwer sam dopina/odpina pokoje przy zmianach członkostwa.
20. **Supabase Realtime nie filtruje zdarzeń DELETE** i zwraca w nich tylko klucz główny — opisany mechanizm nie zadziałałby dla usunięć. → Nie dotyczy po zmianie backendu.

### Logika i UX
21. **Sprzeczność: „Tap na kafelek dnia — dodanie wydarzenia” (5.3) vs „Tap na kafelku — widok dnia / bottom sheet” (5.2).** → Tap = lista wydarzeń dnia (z przyciskiem dodania na ten dzień), long-press = szybkie dodanie.
22. **Walidacja „`until` musi być w przyszłości”** uniemożliwia edycję zakończonej serii z przeszłości. → `until` ≥ data startu.
23. **Powiadomienie „Dołączyłeś do grupy {nazwa}”** wysyłane push do osoby, która właśnie sama dołączyła w aplikacji — bezwartościowe. → Push otrzymują admini grupy: „{Imię} dołączył(a) do grupy {nazwa}”.
24. **Notatka 4 (GestureDetector + pan) przeczy 5.4 (LongPressDraggable + DragTarget)**. DragTarget nie obsługuje „malowania” wielu celów jednym gestem bez dodatkowego stanu. → Jeden detektor gestów na siatce, komórka liczona z pozycji palca (bez konfliktu ze swipe miesięcy — swipe jest blokowany w trybie malowania).
25. **Tekst w pełnym kolorze na tle 20% tego samego koloru** — dla pastelowej palety z prototypu (np. żółty #FDFD96) kontrast jest nieczytelny, co przeczy 10.4. → Kolor tekstu wyliczany automatycznie (przyciemniony w jasnym motywie, rozjaśniony w ciemnym).
26. **Prototyp ma tydzień od niedzieli, dokumentacja od poniedziałku.** → Poniedziałek (polski standard).
27. **„Edycja z przyciskiem Usuń w formularzu” + „Usuń w szczegółach” + „Zapisz w AppBar” + „Create Event na dole” (prototyp)** — zdublowane akcje. → Patrz sekcja 3.

---

## 3. Uporządkowanie interfejsu (bez dublujących się przycisków)

Prototypy (Visily) zawierały kilka elementów prowadzących do tego samego miejsca. Każda akcja ma teraz **jedno** miejsce:

| Akcja | Prototyp | LET`SMEETUP |
|---|---|---|
| Ustawienia | zębatka w nagłówku + zakładka „Settings” + przycisk w drawerze | **tylko zakładka „Ustawienia”** w dolnym pasku |
| Panel boczny | hamburger + avatar | **avatar** w nagłówku otwiera panel (profil, widoczność grup, wyloguj) |
| Motyw | chip „Serene Theme” w kalendarzu + ustawienia | **tylko Ustawienia → Wygląd** |
| Zakładka „Tasks” | w dolnym pasku | usunięta (brak w dokumentacji) → zastąpiona zakładką **„Grupy”** |
| Dodaj grupę | „+” w drawerze + FAB na liście grup | **tylko FAB** na ekranie Grupy |
| Zarządzaj / Opuść grupę | przyciski na karcie + ekran grupy | **tap w kartę** → ekran grupy (tam wszystkie akcje) |
| Zapis wydarzenia | ikona ✓ w AppBar + przycisk na dole | **tylko przycisk na dole** formularza |
| Usuwanie wydarzenia | w formularzu edycji + w szczegółach | **tylko w szczegółach** wydarzenia |
| „Invite Participants” w formularzu | osobna opcja | usunięta — o uczestnikach decyduje wybór **grupy** |
| „Group Activity” + „Push Notifications” | dwa przełączniki o tym samym działaniu | jeden: **Powiadomienia push** |
| Filtr + chipy na liście grup | ikona filtra i chipy | **tylko chipy** (Wszystkie / Admin / Członek) |

---

## 4. Czego świadomie nie ma w v1

Zgodnie z sekcją 13.2/13.3 dokumentacji: widok tygodniowy/dzienny, wyszukiwanie wydarzeń, deep linki,
eksport iCal, reakcje, załączniki, chat, widgety. Architektura (REST + sync + realtime) ich nie blokuje.
