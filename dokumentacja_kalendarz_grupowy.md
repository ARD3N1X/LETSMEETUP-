# 📋 Dokumentacja Techniczna — Aplikacja Kalendarza Grupowego

## 1. Przegląd Projektu

### 1.1 Nazwa robocza
**GroupCal** — kalendarz grupowy z synchronizacją real-time, systemem kont, grup użytkowników oraz unikalnym trybem "malowania" wydarzeń po kalendarzu.

### 1.2 Cel aplikacji
Aplikacja mobilna (iOS/Android) umożliwiająca tworzenie osobistych i grupowych wydarzeń w kalendarzu, z pełną synchronizacją w czasie rzeczywistym między członkami grupy, powiadomieniami push oraz zaawansowanym zarządzaniem widocznością wydarzeń.

### 1.3 Platformy docelowe
- iOS (minimum iOS 14)
- Android (minimum API 24, Android 7.0)
- W przyszłości: Web (PWA) — architektura powinna to umożliwiać

### 1.4 Filozofia UX
- **Minimalizm i przejrzystość** — interfejs bez zbędnych elementów, skupiony na treści.
- **Natychmiastowa informacja zwrotna** — każda akcja użytkownika (dodanie, przesunięcie, usunięcie) ma natychmiastowy efekt wizualny, synchronizacja dzieje się w tle.
- **Gesturalność** — obsługa gestów (przeciąganie, pinch, long-press) jako podstawowy sposób interakcji.
- **Dostępność** — wsparcie dla dynamic font sizes, kontrastów, VoiceOver/TalkBack.

---

## 2. Stack Technologiczny

### 2.1 Frontend
| Warstwa | Technologia | Uzasadnienie |
|---------|-------------|--------------|
| Framework | **Flutter 3.x** (Dart) | Jedna baza kodu na iOS/Android, wysoka wydajność, doskonałe wsparcie dla customowych animacji i gestów. |
| State Management | **Riverpod 2.x** (z Generatorami) | Deklaratywny, testowalny, bezpieczny typowo, świetne wsparcie dla asynchronicznych operacji i cache'owania. |
| Lokalna baza danych | **Drift (SQLite)** + **Hive** (cache) | Drift do strukturalnych danych kalendarza (wydarzenia, grupy), Hive do sesji użytkownika i preferencji. |
| Lokalizacja | **intl** + **flutter_localizations** | Wsparcie dla języka polskiego (domyślny) oraz innych w przyszłości. |
| Nawigacja | **GoRouter** | Deklaratywna nawigacja, deep-linking, ochrona tras wymagających autentykacji. |
| HTTP Client | **Dio** + **Retrofit** | Typowo bezpieczne API, interceptory (tokeny, retry, logowanie). |
| Powiadomienia lokalne | **flutter_local_notifications** | Przypomnienia o wydarzeniach gdy aplikacja jest w tle. |
| Powiadomienia push | **Firebase Messaging (FCM)** | Cross-platform push notifications. |
| Grafika/Avatary | **cached_network_image** | Cache'owanie obrazów profilowych. |
| Picker daty | **syncfusion_flutter_datepicker** (lub własny) | Zaawansowany wybór zakresów dat i powtarzalności. |
| Kolory/Palety | **flex_color_picker** | Wybór koloru kafelka wydarzenia. |

### 2.2 Backend & Infrastruktura
| Komponent | Technologia | Uzasadnienie |
|-----------|-------------|--------------|
| BaaS / Backend | **Supabase** (PostgreSQL + PostgREST + Realtime + Auth + Storage) | Wbudowana autentykacja, realtime subscriptions na poziomie wierszy bazy danych (idealne dla synchronizacji grupowej), relacyjna baza (grupy-wydarzenia-użytkownicy), Edge Functions dla logiki biznesowej. |
| Realtime | **Supabase Realtime** (wbudowane) | Subskrypcje zmian w tabelach — natychmiastowe propagowanie wydarzeń do wszystkich członków grupy. |
| Powiadomienia push | **Supabase Edge Functions** + **FCM** | Trigger w Edge Function wysyła powiadomienie przez FCM do członków grupy przy INSERT/UPDATE wydarzenia. |
| Przechowywanie plików | **Supabase Storage** | Avatary użytkowników, opcjonalnie załączniki do wydarzeń. |
| Backup/Monitoring | **Supabase Dashboard** | Automatyczne backupy, logi, monitoring RLS. |

### 2.3 Architektura komunikacji
```
[Flutter App] ←→ [Supabase Client SDK]
                    ├── Auth (JWT)
                    ├── PostgREST (CRUD)
                    ├── Realtime (WebSocket subscriptions)
                    └── Storage (Avatary)
                          ↓
              [Supabase PostgreSQL]
                    ├── RLS Policies (bezpieczeństwo wierszy)
                    ├── Database Triggers
                    └── Edge Functions (logika push, walidacja)
```

---

## 3. Architektura Aplikacji (Frontend)

### 3.1 Warstwy aplikacji (Clean Architecture)
```
lib/
├── main.dart                 # Entry point, inicjalizacja providerów
├── app.dart                  # MaterialApp/CupertinoApp z dynamicznym theming
├── core/                     # Rdzeń aplikacji
│   ├── constants/            # Stałe (kolory domyślne, formaty dat)
│   ├── errors/               # Klasy wyjątków (Failure, ServerFailure, CacheFailure)
│   ├── extensions/           # Rozszerzenia Dart/Flutter (DateTime, Color, String)
│   ├── theme/                # Definicje ThemeData (light/dark), ThemeNotifier
│   └── utils/                # Helpery (formatowanie dat, walidatory)
├── data/                     # Warstwa danych
│   ├── datasources/          # Źródła danych (local: Drift, remote: Supabase)
│   ├── models/               # Modele DTO (serializacja JSON ↔ obiekt)
│   └── repositories/         # Implementacje repozytoriów
├── domain/                   # Warstwa domeny (niezależna od frameworka)
│   ├── entities/             # Encje czyste (Event, User, Group, CalendarVisibility)
│   ├── repositories/         # Abstrakcyjne interfejsy repozytoriów
│   └── usecases/             # Przypadki użycia (GetEvents, CreateEvent, ToggleGroupVisibility)
├── presentation/             # Warstwa prezentacji (Flutter-specific)
│   ├── providers/            # Riverpod providers (state, notifiers)
│   ├── pages/                # Ekrany (Screens)
│   └── widgets/              # Wielokrotnego użytku widgety
└── services/                 # Usługi globalne
    ├── notification_service.dart      # FCM + local notifications
    ├── sync_service.dart              # Logika synchronizacji offline-first
    └── navigation_service.dart        # Globalny dostęp do nawigacji
```

### 3.2 State Management — szczegóły
- **Global state**: `UserSession` (zalogowany użytkownik, token JWT), `AppSettings` (motyw, język, powiadomienia ON/OFF).
- **Feature state**: Każdy ekran ma własnego `StateNotifier`/`AsyncNotifier`.
- **Cache i synchronizacja**: Lokalna baza Drift jest źródłem prawdy dla UI. W tle działa `SyncService`, który:
  1. Zapisuje zmiany lokalnie natychmiast (optimistic UI).
  2. Wysyła do Supabase w tle.
  3. Odbiera zmiany z Realtime i aktualizuje lokalną bazę.
  4. Rozwiązuje konflikty (last-write-wins z timestamp + vector clock opcjonalnie).

---

## 4. Model Danych (Encje i Relacje)

### 4.1 Encje (Domain Layer)

#### User (Użytkownik)
```yaml
id: UUID (PK, z Supabase Auth)
email: String (unikalny)
display_name: String (max 50 znaków)
avatar_url: String? (URL do Supabase Storage)
created_at: DateTime
updated_at: DateTime
settings: UserSettings (embedded)
```

#### UserSettings (Preferencje użytkownika)
```yaml
theme_mode: Enum {system, light, dark}
notifications_enabled: Bool
default_event_color: String (hex, np. "#FF5733")
language: String (np. "pl", "en")
```

#### Group (Grupa)
```yaml
id: UUID (PK)
name: String (max 100 znaków)
description: String? (max 500 znaków)
created_by: UUID (FK → User.id)
created_at: DateTime
updated_at: DateTime
invite_code: String? (unikalny, 8 znaków alfanumerycznych, opcjonalnie do zapraszania)
```

#### GroupMember (Członek grupy — tabela łącząca)
```yaml
id: UUID (PK)
group_id: UUID (FK → Group.id)
user_id: UUID (FK → User.id)
role: Enum {admin, member}
joined_at: DateTime
# visibility w UI jest lokalna, nie w bazie — patrz CalendarVisibility
```

#### CalendarVisibility (Widoczność grup w kalendarzu użytkownika)
> **UWAGA**: To jest encja lokalna (Drift), nie wysyłana na serwer. Każdy użytkownik sam decyduje, które grupy widzi w swoim kalendarzu.
```yaml
user_id: UUID (PK, część PK)
group_id: UUID (PK, część PK)
is_visible: Bool (default: true)
```

#### Event (Wydarzenie)
```yaml
id: UUID (PK)
title: String (max 200 znaków, wymagane)
description: String? (max 2000 znaków)
created_by: UUID (FK → User.id)
group_id: UUID? (FK → Group.id, NULL = wydarzenie prywatne)
start_date: DateTime (data rozpoczęcia, wymagane)
end_date: DateTime? (data zakończenia, jeśli NULL = całodniowe)
is_all_day: Bool (default: false)
color: String (hex, np. "#4CAF50")
recurrence_rule: RecurrenceRule? (opcjonalnie, patrz niżej)
recurrence_parent_id: UUID? (FK → Event.id, dla instancji powtarzających się)
is_recurring: Bool (obliczane, true jeśli recurrence_rule != null)
created_at: DateTime
updated_at: DateTime
```

#### RecurrenceRule (Reguła powtarzalności)
```yaml
frequency: Enum {daily, weekly, monthly, yearly}
interval: Int (co ile jednostek, default: 1, np. co 2 tygodnie)
until: DateTime? (data końca serii)
count: Int? (ile razy się powtórzy)
by_week_day: List<int>? (dni tygodnia: 0=pon, 6=ndz, dla weekly)
by_month_day: List<int>? (dni miesiąca, dla monthly)
```

#### EventInstance (Instancja wydarzenia powtarzającego się)
> **Logika**: Wydarzenia powtarzające się są przechowywane jako jeden rekord (master) + wygenerowane instancje na potrzeby wyświetlania. Modyfikacja pojedynczej instancji tworzy override.
```yaml
id: UUID (PK)
master_event_id: UUID (FK → Event.id)
instance_date: DateTime (konkretna data wystąpienia)
is_override: Bool (czy ta instancja ma inne dane niż master)
override_title: String?
override_color: String?
override_start_date: DateTime?
override_end_date: DateTime?
```

### 4.2 Diagram relacji (ERD — opisowy)
```
User ||--o{ GroupMember : "jest członkiem"
Group ||--o{ GroupMember : "zawiera"
Group ||--o{ Event : "zawiera wydarzenia"
User ||--o{ Event : "tworzy"
Event ||--o{ EventInstance : "generuje"
Event ||--o{ Event : "parent recurrence (self-ref)"
```

### 4.3 Polityki bezpieczeństwa wierszy (RLS) — Supabase
- **events**: Użytkownik może czytać wydarzenia, gdzie `group_id` jest w grupach, do których należy. Tworzyć/edytować/usunąć tylko własne wydarzenia (lub gdy jest adminem grupy).
- **groups**: Czytać może tylko grupy, do których należy. Tworzyć — każdy zalogowany. Edytować — tylko admin.
- **group_members**: Czytać członków swoich grup. Dodawać — admin lub przez invite code.

---

## 5. Funkcjonalności Szczegółowe

### 5.1 System motywów (Light / Dark / System)

#### Wymagania
- Aplikacja wspiera trzy tryby: **jasny**, **ciemny**, **systemowy** (podąża za ustawieniami OS).
- Przełącznik znajduje się w **Ustawieniach** (SettingsPage).
- Zmiana motywu jest natychmiastowa (bez restartu aplikacji).
- Kolory są definiowane w sposób semanticzny (nie hardkodowane):
  - `surface` — tło kalendarza
  - `surfaceVariant` — tło kafelków dni
  - `primary` — akcenty, przyciski, zaznaczenia
  - `onSurface` — tekst główny
  - `eventColors` — paleta 16 predefiniowanych kolorów do wyboru dla wydarzeń (taka sama w obu motywach, ale z różną przezroczystością/tonacją tła w zależności od motywu).

#### Implementacja
- `ThemeNotifier` (Riverpod) przechowuje `ThemeMode`.
- `App` widget nasłuchuje `ThemeNotifier` i przekazuje `themeMode` do `MaterialApp`.
- Lokalna persystencja w `Hive` — przy starcie aplikacji odczytany jest ostatni wybór.
- **Paleta kolorów**:
  - Jasny: białe/szare tło, ciemny tekst, kolorowe akcenty.
  - Ciemny: `#121212` tło, jasny tekst, kolory wydarzeń bardziej nasycone.

---

### 5.2 Ekran Kalendarza (Główny)

#### Layout
```
┌─────────────────────────────────────┐
│ [Menu]  Miesiąc Rok  [Dzisiaj]    │  ← AppBar
├─────────────────────────────────────┤
│ Pn Wt Śr Cz Pt So Nd               │  ← Nagłówki dni tygodnia
├─────────────────────────────────────┤
│                                     │
│  [1]  [2]  [3]  [4]  [5]  [6]  [7] │  ← Siatka dni
│       [Wydarzenie A]                │     (kafelek dnia z miniaturkami
│  [8]  [9]  [10] ...                 │      wydarzeń wewnątrz)
│                                     │
│  Każdy kafelek to InkWell z       │
│  wysokością proporcjonalną do     │
│  dostępnej przestrzeni.           │
│                                     │
├─────────────────────────────────────┤
│ [+] Dodaj wydarzenie (FAB)         │  ← FloatingActionButton
└─────────────────────────────────────┘
```

#### Pasek boczny (Drawer / BottomSheet na mobilnym)
- **Sekcja "Moje grupy"**:
  - Lista grup, do których należy zalogowany użytkownik.
  - Każda grupa ma **Checkbox** (lub Toggle) z nazwą grupy i kolorem identyfikacyjnym.
  - Domyślnie wszystkie grupy są **zaznaczone** (widoczne).
  - Odznaczenie grupy natychmiast filtruje wydarzenia w kalendarzu — wydarzenia z tej grupy znikają z widoku.
  - Grupa ma swój domyślny kolor (np. pasek z lewej), ale wydarzenia w grupie mogą mieć własne kolory.
- **Sekcja "Prywatne"**: Zawsze widoczna, nie da się odznaczyć (zawiera wydarzenia bez `group_id`).
- **Sekcja "Ustawienia"**: Przycisk prowadzący do SettingsPage.
- **Sekcja "Wyloguj"**.

#### Nawigacja w kalendarzu
- **Przesunięcie w lewo/prawo** (gest swipe) — zmiana miesiąca z animacją przesunięcia.
- **Kliknięcie nagłówka miesiąca** — otwiera `MonthYearPicker` do szybkiego skoku.
- **Przycisk "Dzisiaj"** — natychmiastowy powrót do bieżącego miesiąca z animacją.
- **Zoom/Pinch** (opcjonalnie, v2): pinch na kalendarzu przełącza widok miesięczny ↔ tygodniowy.

#### Kafelek dnia (DayCell)
- Wyświetla numer dnia (góra prawo lub lewo).
- Jeśli dzień = dzisiaj — zaznaczony okrągłym tłem w kolorze `primary`.
- Wewnątrz kafelka: lista miniatur wydarzeń (max 3-4 widoczne, reszta "+2 więcej").
- **Miniatura wydarzenia**:
  - Tło w kolorze wydarzenia (z przezroczystością 20% tekst w pełnym kolorze).
  - Tekst: tytuł wydarzenia (skrócony, max 1 linia).
  - Jeśli wydarzenie należy do innego użytkownika z grupy — **z lewej strony mini avatar** (koło, 16px) twórcy wydarzenia.
  - Jeśli wydarzenie jest całodniowe — brak godziny, tylko tytuł.
  - Jeśli wydarzenie ma godzinę — format "14:00 Tytuł".
- **Long-press na kafelku** — szybkie dodanie wydarzenia (modal z tytułem).
- **Tap na kafelku** — przejście do widoku dnia (DayView) lub otwarcie bottom sheet z listą wydarzeń tego dnia.

---

### 5.3 Dodawanie / Edycja Wydarzenia

#### Trigger
- Tap na FAB "+" — dodanie wydarzenia na bieżącą datę.
- Tap na kafelek dnia — dodanie wydarzenia na ten dzień.
- Tap na istniejące wydarzenie — edycja.

#### Modal / BottomSheet / Full-screen dialog
W zależności od złożoności — full-screen dialog z formularzem.

#### Pola formularza
1. **Tytuł** (TextField, wymagane, max 200 znaków, autofocus).
2. **Opis** (TextField, opcjonalne, max 2000 znaków, max 5 linii).
3. **Data i czas**:
   - **Początek**: DatePicker + TimePicker (jeśli nie całodniowe).
   - **Koniec**: DatePicker + TimePicker (opcjonalne, jeśli NULL = całodniowe).
   - **Toggle "Całodniowe"** — przełącza widok godzinowy ↔ datowy.
4. **Kolor kafelka**:
   - Grid 16 predefiniowanych kolorów (paleta Material + pastelowe).
   - Tap zaznacza, zaznaczony ma ring wokół.
   - Domyślnie: kolor z `UserSettings.default_event_color`.
5. **Grupa**:
   - Dropdown: "Prywatne" lub lista grup użytkownika.
   - Domyślnie: "Prywatne" (lub ostatnio wybrana).
   - **Ważne**: Jeśli wybierzemy grupę, wydarzenie jest od razu widoczne dla członków grupy po zapisie.
6. **Powtarzalność** (Rozwijana sekcja):
   - Toggle "Powtarzaj".
   - Jeśli ON:
     - **Częstotliwość**: Dropdown {Codziennie, Co tydzień, Co miesiąc, Co rok}.
     - **Co ile**: Number input (default 1, min 1, max 99).
     - **Koniec serii**: Radio group {Nigdy, Do daty (DatePicker), Po N wystąpieniach (Number input)}.
     - Dla "Co tydzień": wybór dni tygodnia (chipset: Pn Wt Śr Cz Pt So Nd).
7. **Przyciski**:
   - "Anuluj" (zamyka, discard changes).
   - "Zapisz" (walidacja → zapis lokalny → zapis remote → powiadomienie grupy).
   - W trybie edycji: "Usuń" (z potwierdzeniem: "Usuń to wydarzenie / Usuń całą serię").

#### Walidacja
- Tytuł niepusty.
- Data końcowa ≥ data początkowa.
- Jeśli powtarzalność — `until` musi być w przyszłości lub `count` > 0.

#### Po zapisie
1. Optimistic update: wydarzenie pojawia się w kalendarzu natychmiast.
2. W tle: zapis do Drift, potem zapis do Supabase.
3. Jeśli grupowe: Supabase Realtime propaguje do innych członków.
4. Jeśli grupowe: Edge Function wysyła push notification do członków grupy (poza twórcą).

---

### 5.4 Tryb "Malowania" Wydarzeń (Paint Mode)

#### Opis funkcji
Unikalna funkcja umożliwiająca szybkie kopiowanie lub przesuwanie wydarzenia na wiele dni poprzez gest przeciągania (drag) po siatce kalendarza.

#### Flow użytkownika
1. Użytkownik **klika** na istniejące wydarzenie (long-press lub ikona pędzla w modalu szczegółów).
2. Wydarzenie przechodzi w tryb **"Malowania"** — wizualnie kafelek wydarzenia "przykleja się" do palca/kursora (drag avatar), a kafelek źródłowy staje się półprzezroczysty (wskazanie, że jest w trybie edycji).
3. Użytkownik **przeciąga** palec po kolejnych kafelkach dni w siatce kalendarza.
4. Każdy kafelek dnia, nad którym przesuwa się palec, jest **podświetlany** (highlight z kolorem wydarzenia, np. border lub tło z 30% opacity).
5. Po **zwolnieniu palca**:
   - Jeśli tryb = **Kopiowanie** (domyślny): na każdym zaznaczonym dniu tworzona jest kopia wydarzenia (z tym samym tytułem, kolorem, godziną, ale inną datą). Jeśli wydarzenie było powtarzające się — kopie są pojedynczymi (non-recurring) wydarzeniami.
   - Jeśli tryb = **Przesuwanie** (opcja w UI): wydarzenie jest usuwane z dnia źródłowego i tworzone na dniu docelowym (tylko jeden dzień, nie multi-select).
6. Tryb malowania kończy się automatycznie po zwolnieniu lub po kliknięciu "X" (floating chip "Zakończ malowanie").

#### Szczegóły techniczne (dla AI)
- Użyj `LongPressDraggable` lub `Draggable` z `feedback` zawierającym miniaturę wydarzenia.
- Siatka kalendarza musi być opakowana w `DragTarget` na poziomie każdego `DayCell`.
- Podczas drag-over: `onWillAccept` + `onMove` → aktualizacja stanu tymczasowego (highlight dnia).
- Batch operation: przy zwolnieniu na wielu dniach, wykonaj transakcję lokalną (Drift) tworzącą wiele rekordów, potem batch insert do Supabase (lub pojedyncze inserty w pętli, jeśli API nie wspiera batch — w Supabase można użyć `.upsert()` z listą).
- **Undo**: Po zakończeniu malowania pojawia się SnackBar z akcją "Cofnij" (przez 5 sekund), która usuwa utworzone kopie.

---

### 5.5 System Grup

#### Tworzenie grupy
- **Ekran**: "Nowa grupa" (dostępny z Drawera lub Ustawień).
- **Pola**:
  - Nazwa grupy (wymagana, max 100 znaków).
  - Opis (opcjonalny).
  - Kod zaproszenia (auto-generowany, 8 znaków, z możliwością regeneracji).
- **Po utworzeniu**:
  - Twórca automatycznie jest `admin` w `GroupMember`.
  - Grupa pojawia się na pasku bocznym (Drawer).
  - Domyślnie `is_visible = true` w lokalnej tabeli `CalendarVisibility`.

#### Zapraszanie do grupy
- **Metoda 1: Kod zaproszenia**.
  - Admin udostępnia kod (np. "ABC12345").
  - Użytkownik wchodzi w "Dołącz do grupy", wpisuje kod.
  - Walidacja kodu → dodanie do `GroupMember` z rolą `member`.
- **Metoda 2: Link (deep link)** (opcjonalnie v2).
  - `groupcal://join/ABC12345` — otwiera aplikację i automatycznie dołącza.

#### Zarządzanie członkami (Admin)
- Lista członków z avatarami.
- Usuwanie członków (oprócz siebie).
- Zmiana roli (admin ↔ member).
- Usunięcie grupy (tylko admin, z potwierdzeniem hasłem).

#### Widoczność grupy w kalendarzu
- W Drawerze obok nazwy grupy: **Checkbox** (lub Switch).
- Stan jest lokalny (`CalendarVisibility` w Drift).
- Zmiana stanu natychmiast filtruje zapytanie do lokalnej bazy — wydarzenia z niezaznaczonych grup nie są wyświetlane.
- **Nie wpływa na synchronizację** — wydarzenia nadal są synchronizowane w tle, tylko nie renderowane.

---

### 5.6 Synchronizacja Real-Time

#### Wymaganie kluczowe
Zmiany w kalendarzu grupowym muszą być widoczne natychmiast (czas propagacji < 1s) u wszystkich członków grupy, którzy mają tę grupę zaznaczoną jako widoczną.

#### Mechanizm
1. **Supabase Realtime Subscriptions**:
   - Po zalogowaniu aplikacja subskrybuje kanał `events` z filtrem: `group_id IN (lista_id_grup_użytkownika)`.
   - Używa PostgreSQL `LISTEN/NOTIFY` przez WebSocket.
2. **Eventy nasłuchiwane**:
   - `INSERT` na tabeli `events` — nowe wydarzenie w grupie.
   - `UPDATE` na tabeli `events` — edycja wydarzenia (zmiana tytułu, daty, koloru).
   - `DELETE` na tabeli `events` — usunięcie wydarzenia.
3. **Flow danych**:
   ```
   [Użytkownik A dodaje wydarzenie]
           ↓
   [Supabase INSERT events]
           ↓
   [Realtime Broadcast] → WebSocket → [Klient B, C, D...]
           ↓
   [Flutter: SyncService odbiera payload]
           ↓
   [Zapis do Drift (lokalna baza)]
           ↓
   [Riverpod invalidates provider → UI rebuild]
   ```
4. **Konflikty**:
   - Jeśli użytkownik offline dokonał zmian, a w międzyczasie przyszła zmiana z serwera:
   - Strategia: **Timestamp-based last-write-wins**.
   - Każdy rekord ma `updated_at`. Przy synchronizacji porównujemy `updated_at` lokalny vs zdalny. Zdalny wygrywa, jeśli jest nowszy.
   - Dla bezpieczeństwa: jeśli lokalna zmiana jest nowsza ale niezsynchronizowana — wykonaj push lokalnych zmian, potem apply remote.

#### Optymalizacja
- Subskrypcje są aktywne tylko dla grup widocznych (optymalizacja, ale można subskrybować wszystkie dla spójności danych).
- Przy przełączaniu widoczności grupy — nie trzeba ponownie subskrybować, filtr jest lokalny.

---

### 5.7 Powiadomienia (Notifications)

#### Typy powiadomień

##### A. Powiadomienia push (FCM)
**Włączane/wyłączane globalnie w Ustawieniach.**

1. **Nowe wydarzenie w grupie**:
   - Trigger: `INSERT` na `events` gdzie `group_id IS NOT NULL`.
   - Edge Function `notify-group-members`:
     - Pobiera listę członków grupy (poza twórcą).
     - Sprawdza, czy mają `notifications_enabled = true` w profilu.
     - Wysyła FCM do każdego z tokenem.
   - Treść: `"{Imię} dodał(a) wydarzenie: {Tytuł wydarzenia} w grupie {Nazwa grupy}"`.
   - Tap na powiadomienie: otwiera aplikację na danym dniu kalendarza.

2. **Edycja wydarzenia w grupie** (opcjonalnie, v2):
   - Trigger: `UPDATE` na `events`.
   - Treść: `"{Imię} zmienił(a) wydarzenie: {Tytuł}"`.

3. **Zaproszenie do grupy**:
   - Trigger: dołączenie przez kod/link.
   - Treść: `"Dołączyłeś do grupy {Nazwa grupy}"`.

##### B. Powiadomienia lokalne (flutter_local_notifications)
- **Przypomnienia o wydarzeniach**:
  - Użytkownik może ustawić przypomnienie X minut przed wydarzeniem (w formularzu wydarzenia, domyślnie 15 min).
  - Zaplanowane lokalnie, nie wymagają internetu.
  - Wyświetlane nawet gdy aplikacja jest zamknięta.
  - Po wykonaniu — tap otwiera szczegóły wydarzenia.

#### Uprawnienia
- Przy pierwszym uruchomieniu: prośba o zgodę na powiadomienia (iOS) — użyj `permission_handler`.
- W Ustawieniach: toggle "Powiadomienia push" i "Przypomnienia o wydarzeniach" (osobno).

---

### 5.8 Autentykacja i Autoryzacja

#### Rejestracja
- Email + hasło (Supabase Auth).
- Walidacja: email format, hasło min 8 znaków, 1 wielka litera, 1 cyfra.
- Po rejestracji: wysłanie emaila weryfikacyjnego (Supabase default).
- Po weryfikacji: utworzenie rekordu w tabeli `profiles` (trigger w PostgreSQL: `on auth.user created → INSERT INTO public.profiles`).

#### Logowanie
- Email + hasło.
- **"Zapamiętaj mnie"** — persystencja sesji w secure storage (flutter_secure_storage).
- Automatyczne odświeżanie tokena JWT (Supabase SDK robi to automatycznie).

#### Odzyskiwanie hasła
- Standardowy flow Supabase: email z linkiem resetującym.

#### Wylogowanie
- Czyszczenie sesji, lokalnej bazy Drift (opcjonalnie: tylko user-specific tables, zachować cache?), nawigacja do ekranu logowania.

---

## 6. Specyfikacja UI/UX — Ekrany i Komponenty

### 6.1 Ekran Logowania / Rejestracji
- Tło: gradient lub ilustracja (light/dark adaptive).
- Formularz: email, hasło, przycisk "Zaloguj" / "Utwórz konto".
- Toggle między login ↔ register.
- Link "Nie pamiętasz hasła?".
- Walidacja inline (czerwone podpowiedzi pod polami).
- Loading state na przycisku (CircularProgressIndicator).

### 6.2 Ekran Główny (Kalendarz Miesięczny)
- **AppBar**:
  - Leading: ikona menu (hamburger) otwierająca Drawer.
  - Title: "Miesiąc Rok" (np. "Sierpień 2026") — klikalne, otwiera picker.
  - Actions: ikona "Dzisiaj" (kółko z kropką), ikona wyszukiwania (opcjonalnie v2).
- **Drawer (wysuwany z lewej)**:
  - Header: Avatar + Imię/Nazwa + Email użytkownika.
  - Sekcja "Moje grupy" (ListView z checkboxami).
  - Divider.
  - "Ustawienia" (ikona zębatek).
  - "Wyloguj" (ikona wyjścia, na dole).
- **Body**: Siatka kalendarza (GridView.builder, 7 kolumn).
- **FAB**: Przycisk "+" (z ikoną dodawania), umieszczony w prawym dolnym rogu.

### 6.3 Ekran Ustawień (SettingsPage)
- **ListTile sekcje**:
  - "Motyw" — podtytuł aktualnego trybu, tap przechodzi do podstrony z trzema opcjami (radio list): Systemowy, Jasny, Ciemny.
  - "Powiadomienia" — Toggle "Włącz powiadomienia push", Toggle "Włącz przypomnienia o wydarzeniach".
  - "Domyślny kolor wydarzeń" — tap otwiera ColorPicker, zapis do profilu.
  - "Język" — Dropdown {Polski, English}.
  - "O aplikacji" — wersja, polityka prywatności.
- **AppBar**: Tytuł "Ustawienia", strzałka wstecz.

### 6.4 Ekran Szczegółów Wydarzenia (EventDetailPage / BottomSheet)
- **Widok górny**:
  - Pasek w kolorze wydarzenia (wysokość 120px) z tytułem i datą.
  - Avatar twórcy (jeśli grupowe) + imię twórcy.
- **Sekcje**:
  - Tytuł (duży, bold).
  - Data i godzina (ikona zegara) — format: "Wtorek, 26 sierpnia 2026, 14:00 – 15:30".
  - Powtarzalność (jeśli dotyczy): "Powtarza się co tydzień w środy".
  - Opis (jeśli podany).
  - Grupa (badge z nazwą grupy, kolor tła grupy).
- **Akcje**:
  - FAB/Przycisk "Edytuj" (ikona ołówka).
  - Przycisk "Maluj po kalendarzu" (ikona pędzla) — aktywuje Paint Mode.
  - Przycisk "Usuń" (ikona kosza, kolor czerwony) — z potwierdzeniem.

### 6.5 Ekran Grup (GroupsPage)
- Lista kart (Card) grup.
- Każda karta:
  - Kolor identyfikacyjny grupy (pasek z lewej).
  - Nazwa grupy (bold).
  - Liczba członków (podtytuł).
  - Rola użytkownika (badge: Admin / Członek).
  - Przycisk "Zarządzaj" (jeśli admin) lub "Opuść grupę".
- FAB "+" — tworzenie nowej grupy.

### 6.6 Ekran Zarządzania Grupą (GroupManagementPage)
- **AppBar**: Nazwa grupy.
- **Tabs** (lub sekcje):
  - **Członkowie**: Lista z avatar, imię, rola, przycisk usuń (admin only).
  - **Ustawienia**: Nazwa, opis, kod zaproszenia (z ikoną kopiuj), przycisk "Usuń grupę" (czerwony, admin only).

### 6.7 Ekran Dodawania/Edycji Wydarzenia (EventFormPage)
- Full-screen dialog z AppBar (tytuł: "Nowe wydarzenie" / "Edytuj wydarzenie").
- Formularz w ScrollView.
- Przycisk zapisu w AppBar (ikona check).
- Walidacja inline.
- Animowane rozwijanie sekcji powtarzalności.

---

## 7. Logika Biznesowa — Reguły i Ograniczenia

### 7.1 Wydarzenia
- Użytkownik może tworzyć wydarzenia prywatne (bez grupy) i grupowe.
- Wydarzenie grupowe jest widoczne dla wszystkich członków grupy, którzy mają grupę zaznaczoną jako widoczną.
- Tylko twórca (lub admin grupy) może edytować/usunąć wydarzenie grupowe.
- Członek grupy może widzieć, ale NIE edytować cudzych wydarzeń.
- Wydarzenie prywatne jest widoczne tylko dla twórcy.

### 7.2 Grupy
- Grupa musi mieć co najmniej jednego admina (twórca). Admin nie może opuścić grupy bez przekazania roli innemu członkowi.
- Kod zaproszenia jest unikalny w całym systemie, 8 znaków, case-insensitive.
- Maksymalna liczba członków grupy: 100 (soft limit, konfigurowalny).
- Użytkownik może należeć do maksymalnie 20 grup.

### 7.3 Synchronizacja
- Wszystkie operacje CRUD na wydarzeniach/grupach są wykonywane lokalnie natychmiast (optimistic UI), a następnie synchronizowane z serwerem.
- Jeśli synchronizacja zawiedzie (brak internetu): zmiany są kolejkowane lokalnie. Przywrócenie połączenia = automatyczna synchronizacja (retry z backoff).
- Użytkownik musi być poinformowany o błędzie synchronizacji (SnackBar: "Brak połączenia. Zmiany zostaną zsynchronizowane później.").

### 7.4 Powtarzalność
- Wydarzenie powtarzające się jest przechowywane jako jeden rekord master.
- Instancje są generowane lokalnie na podstawie reguły przy renderowaniu kalendarza (do widoku miesiąca/tygodnia).
- Modyfikacja mastera = zmiana wszystkich przyszłych instancji (i przeszłych, jeśli użytkownik wybierze).
- Modyfikacja pojedynczej instancji = tworzy `EventInstance` z `is_override = true`, który nadpisuje mastera w danym dniu.
- Usunięcie pojedynczej instancji powtarzającego się wydarzenia = utworzenie `EventInstance` z flagą `is_cancelled = true` (lub osobna tabela wyjątków).

---

## 8. API & Protokoły (Specyfikacja dla Backend AI)

### 8.1 Tabele Supabase (PostgreSQL)

#### profiles
```sql
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  display_name text not null,
  avatar_url text,
  default_event_color text default '#4CAF50',
  notifications_enabled boolean default true,
  theme_mode text default 'system', -- 'system' | 'light' | 'dark'
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

#### groups
```sql
create table groups (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  created_by uuid references profiles(id) not null,
  invite_code text unique,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

#### group_members
```sql
create table group_members (
  id uuid default gen_random_uuid() primary key,
  group_id uuid references groups(id) on delete cascade not null,
  user_id uuid references profiles(id) on delete cascade not null,
  role text default 'member' check (role in ('admin', 'member')),
  joined_at timestamptz default now(),
  unique(group_id, user_id)
);
```

#### events
```sql
create table events (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  created_by uuid references profiles(id) not null,
  group_id uuid references groups(id) on delete set null,
  start_date timestamptz not null,
  end_date timestamptz,
  is_all_day boolean default false,
  color text default '#4CAF50',
  recurrence_rule jsonb, -- zserializowany obiekt RecurrenceRule
  recurrence_parent_id uuid references events(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

#### event_instances (opcjonalnie, dla override'ów)
```sql
create table event_instances (
  id uuid default gen_random_uuid() primary key,
  master_event_id uuid references events(id) on delete cascade not null,
  instance_date date not null,
  is_override boolean default false,
  override_title text,
  override_color text,
  override_start_date timestamptz,
  override_end_date timestamptz,
  is_cancelled boolean default false,
  unique(master_event_id, instance_date)
);
```

### 8.2 Edge Functions (Deno/TypeScript)

#### `notify-group-members`
- Trigger: `INSERT` lub `UPDATE` na `events` gdzie `group_id IS NOT NULL`.
- Input: `event_id`, `group_id`, `action` ("created" | "updated" | "deleted").
- Logic:
  1. Pobierz `group_members` dla `group_id` (wykluczając `created_by`).
  2. Dla każdego członka: pobierz `fcm_token` z `profiles` (jeśli `notifications_enabled = true`).
  3. Wyślij FCM multicast z payload:
     ```json
     {
       "title": "Nowe wydarzenie w {group_name}",
       "body": "{creator_name} dodał: {event_title}",
       "data": { "event_id": "...", "group_id": "...", "type": "event_created" }
     }
     ```

#### `generate-invite-code`
- Trigger: `INSERT` na `groups`.
- Generuje 8-znakowy alfanumeryczny kod, zapisuje w `groups.invite_code`.

### 8.3 Realtime Subscriptions
- Kanał: `public:events`.
- Filtr: `group_id=in.(id1,id2,id3...)` — lista grup użytkownika.
- Zdarzenia: `INSERT`, `UPDATE`, `DELETE`.
- Payload zawiera pełny rekord wydarzenia.

### 8.4 RLS Policies — szkice

**profiles:**
- SELECT: `auth.uid() = id` (swoj profil) OR EXISTS (SELECT 1 FROM group_members WHERE user_id = profiles.id AND group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid())) (członkowie wspólnych grup mogą widzieć podstawowe dane: display_name, avatar_url).
- UPDATE: `auth.uid() = id`.

**events:**
- SELECT: `created_by = auth.uid()` OR `group_id IN (SELECT group_id FROM group_members WHERE user_id = auth.uid())`.
- INSERT: `auth.uid() = created_by`.
- UPDATE: `auth.uid() = created_by` OR (`group_id IS NOT NULL` AND EXISTS (SELECT 1 FROM group_members WHERE group_id = events.group_id AND user_id = auth.uid() AND role = 'admin')).
- DELETE: jak UPDATE.

---

## 9. Zarządzanie Stanem Offline-First

### 9.1 Strategia
Aplikacja musi działać w trybie offline bez utraty funkcjonalności (oprócz real-time sync i push notifications).

### 9.2 Lokalna baza (Drift)
- Wszystkie encje (`events`, `groups`, `group_members`, `profiles`) mają lokalne odpowiedniki w SQLite.
- Dodatkowe pola lokalne:
  - `sync_status`: Enum {`synced`, `pending_insert`, `pending_update`, `pending_delete`}.
  - `last_modified_locally`: Timestamp.
- Przy starcie aplikacji: załaduj wszystko z lokalnej bazy. W tle: pobierz najnowsze dane z Supabase (lub zsynchronizuj).

### 9.3 Kolejkowanie zmian
- Gdy użytkownik wykonuje akcję offline:
  1. Zapisz do Drift ze statusem `pending_*`.
  2. UI natychmiast aktualizuje się z lokalnych danych.
  3. `SyncService` (nasłuchujący na connectivity) wykrywa brak sieci i odkłada synchronizację.
  4. Przywrócenie sieci: `SyncService` przetwarza kolejkę w kolejności FIFO.
  5. Po sukcesie: aktualizacja `sync_status` na `synced` i `updated_at` z serwera.

### 9.4 Konflikty
- Jeśli serwer zwraca nowszy `updated_at` niż lokalny podczas próby update:
  - Opcja A: Nadpisz lokalne dane serwerowymi (server wins).
  - Opcja B: Pokaż użytkownikowi modal konfliktu (zaawansowane, v2).
  - **Rekomendacja v1**: Server wins, ale zapisz lokalną wersję w osobnej tabeli `conflict_log` do ręcznego review.

---

## 10. Wymagania Niefunkcjonalne

### 10.1 Wydajność
- Renderowanie siatki miesięcznej: < 16ms (60 FPS) przy 30 wydarzeniach widocznych.
- Lazy loading wydarzeń: ładowanie tylko dla widocznego miesiąca + 1 miesiąc wstecz/naprzód.
- Avatary: cache'owane (CachedNetworkImage), max rozmiar 100x100px.
- Baza lokalna: indeksy na `events.start_date`, `events.group_id`, `group_members.user_id`.

### 10.2 Bezpieczeństwo
- Wszystkie dane wrażliwe przechowywane w `flutter_secure_storage` (token JWT, FCM token).
- RLS na wszystkich tabelach — zero trust.
- Walidacja danych po stronie serwera (Edge Functions) i klienta.
- Rate limiting na endpointach zaproszeń (max 10 prób/minutę).

### 10.3 Skalowalność
- Supabase Realtime ma limity połączeń — przy dużej liczbie użytkowników rozważyć batchowanie subskrypcji lub podział na kanały per-grupa.
- FCM multicast: max 500 tokenów na zapytanie (batchowanie).

### 10.4 Dostępność
- Wsparcie dla dużych czcionek (MediaQuery.textScaleFactor).
- Kontrast tekstu na kafelkach wydarzeń: automatyczny dobór koloru tekstu (czarny/biały) w zależności od jasności tła kafelka.
- Etykiety semantyczne (Semantics) dla czytników ekranu na wszystkich interaktywnych elementach.

---

## 11. Scenariusze Edge Case

### 11.1 Użytkownik usunięty z grupy
- Admin usuwa członka z grupy.
- Serwer: `DELETE` z `group_members`.
- Realtime: klient byłego członka otrzymuje event (lub przy następnym fetchu) — wydarzenia grupy znikają z kalendarza.
- Lokalna baza: wydarzenia tej grupy są usunięte (lub oznaczone jako niewidoczne, ale lepiej usunąć dla oszczędności miejsca).

### 11.2 Użytkownik utracił internet w trakcie dodawania wydarzenia
- Optimistic UI: wydarzenie widoczne natychmiast.
- `SyncService`: kolejkuje operację.
- SnackBar: "Zapisano lokalnie. Zsynchronizujemy, gdy wróci połączenie."
- Przywrócenie sieci: auto-sync, SnackBar "Zsynchronizowano".

### 11.3 Dwóch użytkowników edytuje to samo wydarzenie jednocześnie
- Użytkownik A zmienia tytuł na "X".
- Użytkownik B zmienia kolor na "Y".
- Oba requesty trafiają do serwera.
- Last-write-wins na podstawie `updated_at`.
- Wersja, która dotrze później, nadpisuje cały rekord. Aby tego uniknąć w przyszłości — rozważyć partial updates (tylko zmienione pola) lub Operational Transform/CRDT (v2).

### 11.4 Wydarzenie powtarzające się na granicy miesiąca
- Przy renderowaniu siatki: generuj instancje tylko dla widocznego zakresu (pierwszy i ostatni dzień miesiąca, plus dni z poprzedniego/następnego miesiąca wypełniające tydzień).
- Reguła powtarzalności musi być interpretowana zgodnie z iCalendar RRULE (RFC 5545) lub uproszczonym wariantem.

### 11.5 Paint Mode na wydarzenie powtarzające się
- Jeśli użytkownik "maluje" wydarzenie powtarzające się:
  - Domyślnie: tworzone są **pojedyncze, niepowtarzające się kopie** na zaznaczonych dniach (zachowanie najbardziej przewidywalne).
  - Alternatywa (v2): pytanie użytkownika "Czy chcesz utworzyć serie powtarzające się na tych dniach?".

---

## 12. Struktura Nawigacji (Routing)

```
/                           → SplashScreen / AuthGate (sprawdza sesję)
/login                      → LoginPage
/register                   → RegisterPage
/calendar                   → CalendarPage (main shell)
/calendar/day?date=...      → DayDetailPage (opcjonalny widok dnia)
/event/new?date=...         → EventFormPage (tryb tworzenia)
/event/edit/:id             → EventFormPage (tryb edycji)
/event/:id                  → EventDetailPage (szczegóły)
/groups                     → GroupsListPage
/groups/new                 → GroupCreatePage
/groups/:id                 → GroupDetailPage (zarządzanie)
/settings                   → SettingsPage
/settings/theme             → ThemeSettingsPage
```

---

## 13. Checklist dla AI (Cloud AI / Claude / Cursor)

### 13.1 Must Have (MVP)
- [ ] Autentykacja email/hasło przez Supabase Auth.
- [ ] Ekran kalendarza miesięcznego z siatką 7xN.
- [ ] Drawer z listą grup i checkboxami widoczności.
- [ ] Dodawanie/edycja/usuwanie wydarzeń (tytuł, data, kolor, grupa, opis).
- [ ] Wydarzenia grupowe widoczne dla członków z avatarem twórcy.
- [ ] Synchronizacja real-time przez Supabase Realtime.
- [ ] Powiadomienia push (FCM) przy nowym wydarzeniu w grupie.
- [ ] Powiadomienia lokalne (przypomnienia o wydarzeniach).
- [ ] Tryb jasny/ciemny/systemowy z przełącznikiem w ustawieniach.
- [ ] Tworzenie grup, zapraszanie kodem, dołączanie do grup.
- [ ] Lokalna baza Drift z offline-first sync.
- [ ] Tryb "Malowania" wydarzeń po kalendarzu (drag & multi-day paint).
- [ ] Powtarzalność wydarzeń (daily, weekly, monthly, yearly z interwałem i końcem).

### 13.2 Should Have (v1.1)
- [ ] Widok tygodniowy i dzienny.
- [ ] Wyszukiwanie wydarzeń.
- [ ] Deep linking (linki do wydarzeń/grup).
- [ ] Eksport kalendarza (iCal).
- [ ] Reakcje na wydarzenia ("Biorę udział", "Może").

### 13.3 Nice to Have (v2)
- [ ] Współdzielenie zdjęć w wydarzeniach.
- [ ] Chat w grupie.
- [ ] Integracja z kalendarzem systemowym (iOS/Android native calendars).
- [ ] Widget na ekran główny telefonu.

---

## 14. Notatki dla Implementującego AI

1. **Nie hardkoduj kolorów** — użyj `Theme.of(context)` i semantycznych nazw (`surface`, `primaryContainer`, `onSurfaceVariant`).
2. **Używaj Riverpod z `@riverpod` generatorami** — to jest nowoczesny standard, unikaj `ChangeNotifierProvider`.
3. **Drift + Supabase** — zaimplementuj abstrakcyjne repozytorium w warstwie `domain`, a konkretne implementacje w `data`. Umożliwi to łatwą zamianę backendu w przyszłości.
4. **Paint Mode** — to jest najtrudniejszy UX-owo element. Przetestuj na fizycznym urządzeniu. Upewnij się, że gesty nie kolidują ze scrollowaniem kalendarza (użyj `GestureDetector` z `behavior: HitTestBehavior.opaque` i odpowiednim `pan` zamiast `drag`).
5. **Real-time** — subskrypcje muszą być zamykane przy dispose widgetu / logout. Użyj `ref.onDispose` w Riverpod.
6. **FCM Token** — zapisuj token w `profiles.fcm_token` przy każdym starcie aplikacji (token może się zmienić). Obsłuż `onTokenRefresh`.
7. **Różnica czasowa** — wszystkie daty w bazie w UTC, konwersja do lokalnej strefy czasowej w Flutterze (`toLocal()`). Użytkownik widzi zawsze czas lokalny.
8. **Performance siatki** — użyj `CustomScrollView` z `SliverGrid` zamiast zwykłego `GridView`, jeśli standardowy `GridView` ma problemy z ilością wydarzeń. Rozważ `flutter_staggered_grid_view` tylko jeśli naprawdę potrzebny — zwykły Grid 7 kolumn wystarczy.
9. **Avatar na kafelku** — jeśli w jednym dniu jest wiele wydarzeń od różnych osób, avatar może zajmować za dużo miejsca. Rozwiązanie: avatar tylko przy wydarzeniach grupowych, max 1-2 avatary, reszta jako "+".
10. **Testy** — napisz testy widgetowe dla formularza wydarzenia i testy integracyjne dla flow logowania. Użyj `mocktail` + `fake_supabase` (lub wrappera abstrakcyjnego, który można mockować).

---

*Dokumentacja przygotowana jako brief techniczny do generowania kodu przez AI.*
*Wersja: 1.0 | Data: 2026-08-26*
