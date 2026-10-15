class AppConfig {
  AppConfig._();

  static const appName = 'LET`SMEETUP';
  static const version = '1.0.0';

  /// Adres API: `flutter run --dart-define=API_URL=http://10.0.2.2:3000` (lokalny serwer w emulatorze).
  /// Domyślnie serwer w chmurze (Render).
  static const _apiUrlOverride = String.fromEnvironment('API_URL');

  static String get apiUrl {
    if (_apiUrlOverride.isNotEmpty) return _apiUrlOverride;
    return 'https://letsmeetup-api.onrender.com';
  }

  /// Zamienia względne ścieżki z API (np. avatary) na pełne adresy.
  static String? resolveUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '$apiUrl$url';
  }
}
