import 'dart:convert';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:letsmeetup/core/theme.dart';
import 'package:letsmeetup/data/local/database.dart';
import 'package:letsmeetup/data/models.dart';
import 'package:letsmeetup/data/remote/api_client.dart';
import 'package:letsmeetup/presentation/pages/auth/login_page.dart';
import 'package:letsmeetup/presentation/pages/event/event_form_page.dart';
import 'package:letsmeetup/presentation/providers/core_providers.dart';
import 'package:letsmeetup/services/notification_service.dart';
import 'package:letsmeetup/services/push_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API bez sieci — odpowiada natychmiast błędem połączenia (bez prawdziwych żądań i timerów).
class OfflineApi extends ApiClient {
  OfflineApi(super.tokens);

  Never _offline() => throw ApiException(code: 'NETWORK', message: 'offline', isNetwork: true);

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async => _offline();
  @override
  Future<dynamic> post(String path, [Object? body]) async => _offline();
  @override
  Future<dynamic> patch(String path, Object body) async => _offline();
  @override
  Future<dynamic> delete(String path, [Object? body]) async => _offline();
}

Future<void> pumpPage(WidgetTester tester, Widget page, {bool signedIn = false}) async {
  final user = AppUser(id: 'me', email: 'me@example.com', displayName: 'Ja', settings: const UserSettings());
  SharedPreferences.setMockInitialValues({if (signedIn) 'cached_user': jsonEncode(user.toJson())});
  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStore();
  if (signedIn) tokens.refreshToken = 'refresh-token';
  final api = OfflineApi(tokens);
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  await tester.pumpWidget(ProviderScope(
    retry: (_, _) => null,
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      tokenStoreProvider.overrideWithValue(tokens),
      apiProvider.overrideWithValue(api),
      notificationServiceProvider.overrideWithValue(NotificationService()),
      pushServiceProvider.overrideWithValue(PushService(api)),
    ],
    child: MaterialApp(
      theme: AppTheme.build(Brightness.light, const Color(0xFF4FC3F7), googleFonts: false),
      home: page,
    ),
  ));
  await tester.pump();
}

/// Kilka klatek po 100 ms — animacje kończą się bez pumpAndSettle (migający kursor nigdy się nie "uspokaja").
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(() => initializeDateFormatting('pl'));

  testWidgets('login form shows inline validation errors', (tester) async {
    await pumpPage(tester, const LoginPage());
    expect(find.text('Witaj ponownie!'), findsOneWidget);

    await tester.tap(find.text('Zaloguj się'));
    await tester.pump();
    expect(find.text('Podaj adres e-mail'), findsOneWidget);
    expect(find.text('To pole jest wymagane'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'zły-adres');
    await tester.pump();
    expect(find.text('Nieprawidłowy adres e-mail'), findsOneWidget);
  });

  testWidgets('event form requires a title and offers every repeat option', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await pumpPage(tester, EventFormPage(initialDate: DateTime(2026, 8, 14)), signedIn: true);
    expect(find.text('Nowe wydarzenie'), findsOneWidget);
    expect(find.text('Prywatne'), findsOneWidget);

    await tester.tap(find.text('Utwórz wydarzenie'));
    await tester.pump();
    expect(find.text('Podaj nazwę wydarzenia'), findsOneWidget);

    await tester.ensureVisible(find.text('Powtarzaj'));
    await tester.tap(find.text('Powtarzaj'));
    await settle(tester);
    for (final option in ['Nie powtarza się', 'Codziennie', 'Co tydzień', 'Co miesiąc', 'Co rok']) {
      expect(find.text(option), findsOneWidget);
    }
    await tester.ensureVisible(find.text('Co tydzień'));
    await tester.tap(find.text('Co tydzień'));
    await settle(tester);
    expect(find.text('Pt'), findsOneWidget, reason: 'weekday chips for weekly repeat');
  });
}
