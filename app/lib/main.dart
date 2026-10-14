import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/local/database.dart';
import 'data/remote/api_client.dart';
import 'presentation/providers/core_providers.dart';
import 'services/notification_service.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl');
  await initializeDateFormatting('en');

  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStore();
  await tokens.load();
  final notifications = NotificationService();
  await notifications.init();
  final api = ApiClient(tokens);
  final push = PushService(api);
  await push.init();

  runApp(
    ProviderScope(
      // Błędy obsługujemy jawnie (komunikaty dla użytkownika) — bez automatycznych ponowień Riverpoda.
      retry: (_, _) => null,
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(AppDatabase()),
        tokenStoreProvider.overrideWithValue(tokens),
        apiProvider.overrideWithValue(api),
        notificationServiceProvider.overrideWithValue(notifications),
        pushServiceProvider.overrideWithValue(push),
      ],
      child: const LetsMeetUpApp(),
    ),
  );
}
