import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/remote/api_client.dart';
import 'core_providers.dart';
import 'settings_controller.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState {
  const AuthState(this.status, [this.user]);
  final AuthStatus status;
  final AppUser? user;

  bool get isSignedIn => status == AuthStatus.signedIn;
}

class AuthController extends Notifier<AuthState> {
  static const _userKey = 'cached_user';

  ApiClient get _api => ref.read(apiProvider);

  @override
  AuthState build() {
    _api.onSessionExpired = () => unawaited(_clearLocalSession());
    final tokens = ref.read(tokenStoreProvider);
    final cached = ref.read(prefsProvider).getString(_userKey);
    if (tokens.hasSession && cached != null) {
      // Offline-first: wchodzimy od razu z zapamiętanym profilem, odświeżamy go w tle.
      final user = AppUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      Future.microtask(_refreshProfile);
      return AuthState(AuthStatus.signedIn, user);
    }
    if (cached != null) {
      // Poprzednia sesja bez "Zapamiętaj mnie" — nie zostawiamy cudzych danych na urządzeniu.
      Future.microtask(() async {
        await ref.read(databaseProvider).clearAll();
        await ref.read(prefsProvider).remove(_userKey);
      });
    }
    return const AuthState(AuthStatus.signedOut);
  }

  AppUser? get user => state.user;

  Future<void> _refreshProfile() async {
    try {
      final json = await _api.get('/me') as Map<String, dynamic>;
      await _setUser(AppUser.fromJson(json), applySettings: true);
    } on ApiException {
      // Offline — zostajemy przy zapamiętanym profilu.
    }
  }

  Future<void> _setUser(AppUser user, {bool applySettings = false}) async {
    await ref.read(prefsProvider).setString(_userKey, jsonEncode(user.toJson()));
    if (applySettings) await ref.read(settingsProvider.notifier).applyFromServer(user.settings);
    state = AuthState(AuthStatus.signedIn, user);
  }

  Future<void> _onSession(Map<String, dynamic> res) async {
    await ref.read(tokenStoreProvider).save(res['accessToken'] as String, res['refreshToken'] as String);
    await _setUser(AppUser.fromJson((res['user'] as Map).cast<String, dynamic>()), applySettings: true);
  }

  Future<void> login(String email, String password, {required bool remember}) async {
    ref.read(tokenStoreProvider).remember = remember;
    final res = await _api.post('/auth/login', {'email': email, 'password': password});
    await _onSession(res as Map<String, dynamic>);
  }

  /// Zwraca `true`, jeśli trzeba potwierdzić e-mail kodem.
  Future<bool> register(String email, String password, String displayName) async {
    final res = await _api.post('/auth/register', {
      'email': email,
      'password': password,
      'displayName': displayName,
      'language': ref.read(settingsProvider).language,
    }) as Map<String, dynamic>;
    if (res['needsVerification'] == true) return true;
    await _onSession(res);
    return false;
  }

  Future<void> verifyEmail(String email, String code) async =>
      _onSession(await _api.post('/auth/verify-email', {'email': email, 'code': code}) as Map<String, dynamic>);

  Future<void> resendVerification(String email) => _api.post('/auth/resend-verification', {'email': email});

  Future<void> forgotPassword(String email) => _api.post('/auth/forgot-password', {'email': email});

  Future<void> resetPassword(String email, String code, String newPassword) async => _onSession(
        await _api.post('/auth/reset-password', {'email': email, 'code': code, 'newPassword': newPassword})
            as Map<String, dynamic>,
      );

  Future<void> updateDisplayName(String name) async {
    final json = await _api.patch('/me', {'displayName': name}) as Map<String, dynamic>;
    await _setUser(AppUser.fromJson(json));
  }

  Future<void> uploadAvatar(String path) async {
    final json = await _api.upload('/me/avatar', 'avatar', path) as Map<String, dynamic>;
    await _setUser(AppUser.fromJson(json));
  }

  Future<void> removeAvatar() async {
    final json = await _api.delete('/me/avatar') as Map<String, dynamic>;
    await _setUser(AppUser.fromJson(json));
  }

  Future<void> changePassword(String current, String next) =>
      _api.post('/me/password', {'currentPassword': current, 'newPassword': next});

  Future<void> deleteAccount(String password) async {
    await _api.delete('/me', {'password': password});
    await _clearLocalSession();
  }

  Future<void> logout() async {
    await ref.read(pushServiceProvider).unregister();
    final refreshToken = ref.read(tokenStoreProvider).refreshToken;
    if (refreshToken != null) {
      try {
        await _api.post('/auth/logout', {'refreshToken': refreshToken});
      } on ApiException {
        // Offline — token wygaśnie sam.
      }
    }
    await _clearLocalSession();
  }

  Future<void> _clearLocalSession() async {
    if (state.status == AuthStatus.signedOut) return;
    await ref.read(syncServiceProvider).stop();
    await ref.read(tokenStoreProvider).clear();
    await ref.read(databaseProvider).clearAll();
    await ref.read(notificationServiceProvider).cancelAll();
    await ref.read(prefsProvider).remove(_userKey);
    state = const AuthState(AuthStatus.signedOut);
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authProvider).user);
