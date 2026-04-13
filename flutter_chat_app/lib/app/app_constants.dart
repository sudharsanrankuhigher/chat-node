import 'package:flutter/foundation.dart';

class AppConstants {
  static const String _socketUrlOverride = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: '',
  );

  static String get socketUrl {
    if (_socketUrlOverride.isNotEmpty) {
      return _socketUrlOverride;
    }

    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:5000';
      case TargetPlatform.fuchsia:
        return 'http://localhost:5000';
    }
  }
}
