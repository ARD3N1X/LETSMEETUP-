import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config.dart';
import '../../core/l10n.dart';

class ApiException implements Exception {
  ApiException({required this.code, required this.message, this.status, this.isNetwork = false});

  final String code;
  final String message;
  final int? status;

  /// Brak połączenia / timeout / błąd serwera 5xx — operację można ponowić później.
  final bool isNetwork;

  bool get isRetryable => isNetwork || (status != null && status! >= 500);

  @override
  String toString() => 'ApiException($status $code: $message)';
}

/// Tokeny: access w pamięci, refresh (i access) w secure storage, jeśli "Zapamiętaj mnie".
class TokenStore {
  TokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  String? accessToken;
  String? refreshToken;
  bool remember = true;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  Future<void> load() async {
    accessToken = await _storage.read(key: _kAccess);
    refreshToken = await _storage.read(key: _kRefresh);
  }

  Future<void> save(String access, String refresh) async {
    accessToken = access;
    refreshToken = refresh;
    if (remember) {
      await _storage.write(key: _kAccess, value: access);
      await _storage.write(key: _kRefresh, value: refresh);
    }
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  bool get hasSession => refreshToken != null;
}

class ApiClient {
  ApiClient(this.tokens, {String? baseUrl}) : dio = Dio(_options(baseUrl)), _plain = Dio(_options(baseUrl)) {
    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokens.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        final isAuthCall = request.path.startsWith('/auth/');
        if (error.response?.statusCode == 401 && !isAuthCall && request.extra['retried'] != true) {
          try {
            await refresh();
            request.extra['retried'] = true;
            request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
            // Osobna instancja Dio — kolejka interceptorów jest zajęta bieżącym błędem.
            handler.resolve(await _plain.fetch(request));
            return;
          } on ApiException catch (e) {
            if (!e.isNetwork) onSessionExpired?.call();
          } on DioException catch (retryError) {
            handler.next(retryError);
            return;
          }
        }
        handler.next(error);
      },
    ));
  }

  static BaseOptions _options(String? baseUrl) => BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
      );

  final Dio dio;
  final Dio _plain;
  final TokenStore tokens;

  /// Wywoływane, gdy odświeżenie sesji się nie powiodło (np. hasło zmienione na innym urządzeniu).
  void Function()? onSessionExpired;

  Future<void>? _refreshing;

  /// Odświeża access token (jedno żądanie naraz, nawet przy wielu równoległych 401).
  Future<void> refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<void> _doRefresh() async {
    final refreshToken = tokens.refreshToken;
    if (refreshToken == null) throw ApiException(code: 'NO_SESSION', message: 'No session', status: 401);
    final res = await _wrap(() => _plain.post<dynamic>('/auth/refresh', data: {'refreshToken': refreshToken}));
    await tokens.save(res['accessToken'] as String, res['refreshToken'] as String);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _wrap(() => dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, [Object? body]) => _wrap(() => dio.post<dynamic>(path, data: body ?? const {}));

  Future<dynamic> patch(String path, Object body) => _wrap(() => dio.patch<dynamic>(path, data: body));

  Future<dynamic> put(String path, Object body) => _wrap(() => dio.put<dynamic>(path, data: body));

  Future<dynamic> delete(String path, [Object? body]) => _wrap(() => dio.delete<dynamic>(path, data: body));

  Future<dynamic> upload(String path, String field, String filePath) => _wrap(() async {
        final form = FormData.fromMap({field: await MultipartFile.fromFile(filePath)});
        return dio.post<dynamic>(path, data: form, options: Options(contentType: 'multipart/form-data'));
      });

  Future<dynamic> _wrap(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      return res.data;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  static ApiException _toApiException(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException(
        code: 'NETWORK',
        message: tr('Brak połączenia z serwerem', 'Cannot reach the server'),
        isNetwork: true,
      );
    }
    final data = response.data;
    final error = data is Map ? data['error'] : null;
    if (error is Map) {
      return ApiException(
        code: error['code'] as String? ?? 'ERROR',
        message: error['message'] as String? ?? 'Error',
        status: response.statusCode,
      );
    }
    return ApiException(code: 'HTTP_${response.statusCode}', message: 'HTTP ${response.statusCode}', status: response.statusCode);
  }
}

/// Komunikat błędu dla użytkownika.
String errorMessage(Object error) {
  if (error is! ApiException) return tr('Coś poszło nie tak. Spróbuj ponownie.', 'Something went wrong. Please try again.');
  if (error.isNetwork) return tr('Brak połączenia z internetem.', 'No internet connection.');
  return switch (error.code) {
    'INVALID_CREDENTIALS' => tr('Nieprawidłowy e-mail lub hasło.', 'Invalid e-mail or password.'),
    'EMAIL_TAKEN' => tr('Konto z tym adresem już istnieje.', 'An account with this e-mail already exists.'),
    'EMAIL_NOT_VERIFIED' => tr('Potwierdź najpierw adres e-mail.', 'Please verify your e-mail first.'),
    'INVALID_CODE' => tr('Nieprawidłowy kod.', 'Invalid code.'),
    'CODE_EXPIRED' => tr('Kod wygasł — wyślij nowy.', 'The code has expired — request a new one.'),
    'TOO_MANY_ATTEMPTS' => tr('Zbyt wiele prób — wyślij nowy kod.', 'Too many attempts — request a new code.'),
    'INVALID_PASSWORD' => tr('Nieprawidłowe hasło.', 'Wrong password.'),
    'INVALID_INVITE_CODE' => tr('Nie znaleziono grupy o tym kodzie.', 'No group with this code.'),
    'ALREADY_MEMBER' => tr('Już należysz do tej grupy.', 'You are already a member of this group.'),
    'GROUP_FULL' => tr('Grupa osiągnęła limit członków.', 'This group is full.'),
    'TOO_MANY_GROUPS' => tr('Osiągnięto limit 20 grup.', 'You reached the limit of 20 groups.'),
    'LAST_ADMIN' => tr('Najpierw przekaż rolę admina innemu członkowi.', 'Transfer the admin role to another member first.'),
    'ADMIN_ONLY' => tr('Tylko admin grupy może to zrobić.', 'Only a group admin can do this.'),
    'NOT_EVENT_OWNER' => tr('Możesz edytować tylko swoje wydarzenia.', 'You can only edit your own events.'),
    'RATE_LIMITED' => tr('Zbyt wiele prób. Spróbuj za minutę.', 'Too many attempts. Try again in a minute.'),
    'VALIDATION_ERROR' => tr('Sprawdź poprawność danych.', 'Please check the entered data.'),
    _ => error.message,
  };
}
