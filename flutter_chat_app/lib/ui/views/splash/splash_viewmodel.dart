import 'dart:async';

import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../core/services/session_service.dart';

class SplashViewModel extends BaseViewModel {
  final SessionService _sessionService = locator<SessionService>();

  Future<bool> initialise() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return _sessionService.hasAuthToken;
  }
}
