import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/palette.dart';
import '../../data/calendar_repository.dart';
import '../../data/models.dart';
import 'core_providers.dart';

/// Ustawienia użytkownika: zapisywane lokalnie natychmiast, synchronizowane z profilem na serwerze.
class SettingsController extends Notifier<UserSettings> {
  static const _key = 'settings';

  @override
  UserSettings build() {
    final raw = ref.read(prefsProvider).getString(_key);
    final settings = raw == null ? const UserSettings() : UserSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    L10n.lang = settings.language;
    return settings;
  }

  Future<void> update(UserSettings Function(UserSettings s) change, {bool syncToServer = true}) async {
    final next = change(state);
    state = next;
    L10n.lang = next.language;
    await ref.read(prefsProvider).setString(_key, jsonEncode(next.toJson()));
    if (syncToServer && ref.read(tokenStoreProvider).hasSession) {
      await ref.read(databaseProvider).enqueue(OpKind.updateSettings, 'me', {'settings': next.toJson()});
      ref.read(syncServiceProvider).kick();
    }
  }

  /// Ustawienia z profilu na serwerze (po zalogowaniu) — chyba że lokalnie czekają niewysłane zmiany.
  Future<void> applyFromServer(UserSettings settings) async {
    if (await ref.read(databaseProvider).hasOpsFor('me')) return;
    await update((_) => settings, syncToServer: false);
  }
}

final settingsProvider = NotifierProvider<SettingsController, UserSettings>(SettingsController.new);

final themeModeProvider = Provider<ThemeMode>((ref) {
  return switch (ref.watch(settingsProvider.select((s) => s.themeMode))) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

final accentColorProvider = Provider<Color>((ref) => Palette.parse(ref.watch(settingsProvider.select((s) => s.accentColor))));
