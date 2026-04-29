class AppConstants {
  static const String _baseUrlOverride = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '',
  );
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _socketUrlOverride = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: '',
  );
  static const String authToken = String.fromEnvironment(
    'AUTH_TOKEN',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    return 'http://localhost:5000/';
  }

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    return '${baseUrl.replaceAll(RegExp(r'/$'), '')}/api';
  }

  static String get socketUrl {
    if (_socketUrlOverride.isNotEmpty) {
      return _socketUrlOverride;
    }

    return baseUrl.replaceAll(RegExp(r'/$'), '');
  }

  static const Duration requestTimeout = Duration(seconds: 20);
}
