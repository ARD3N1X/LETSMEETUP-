import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../data/remote/api_client.dart';

/// Push przez Firebase Cloud Messaging (darmowe). Działa po dodaniu konfiguracji Firebase
/// (`flutterfire configure` → google-services.json / GoogleService-Info.plist).
/// Bez konfiguracji aplikacja działa normalnie — powiadomienia o aktywności grup
/// są wtedy pokazywane tylko, gdy aplikacja jest otwarta (przez WebSocket).
class PushService {
  PushService(this._api);

  final ApiClient _api;
  bool _available = false;
  String? _token;
  StreamSubscription<String>? _refreshSub;

  final _taps = StreamController<Map<String, dynamic>>.broadcast();

  /// Dane klikniętego powiadomienia push (`type`, `eventId`, `groupId`, `date`).
  Stream<Map<String, dynamic>> get taps => _taps.stream;
  bool get isAvailable => _available;

  Future<void> init() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      debugPrint('Firebase not configured — push disabled ($e)');
      return;
    }
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _taps.add(m.data));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _taps.add(initial.data);
    // Gdy aplikacja jest na pierwszym planie, aktywność pokazuje WebSocket — push pomijamy (bez duplikatów).
  }

  /// Rejestruje urządzenie na serwerze (token może się zmieniać — obsługujemy onTokenRefresh).
  Future<void> register() async {
    if (!_available) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      _token = await messaging.getToken();
      if (_token != null) await _send(_token!);
      await _refreshSub?.cancel();
      _refreshSub = messaging.onTokenRefresh.listen((t) {
        _token = t;
        _send(t);
      });
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  Future<void> _send(String token) async {
    try {
      await _api.post('/me/devices', {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'});
    } catch (e) {
      debugPrint('Device token upload failed: $e');
    }
  }

  Future<void> unregister() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    if (!_available || _token == null) return;
    try {
      await _api.delete('/me/devices', {'token': _token});
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Wylogowanie offline — serwer usunie nieaktualny token przy pierwszej nieudanej wysyłce.
    }
    _token = null;
  }
}
