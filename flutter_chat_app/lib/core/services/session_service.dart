import 'package:stacked/stacked.dart';

import '../models/user_profile.dart';
import '../utils/app_constants.dart';

class SessionService with ListenableServiceMixin {
  SessionService() {
    listenToReactiveValues(<ReactiveValue<dynamic>>[_currentUser, _knownUsers, _authToken]);
  }

  final ReactiveValue<UserProfile?> _currentUser = ReactiveValue<UserProfile?>(null);
  final ReactiveValue<Map<String, UserProfile>> _knownUsers =
      ReactiveValue<Map<String, UserProfile>>(<String, UserProfile>{});
  final ReactiveValue<String?> _authToken = ReactiveValue<String?>(AppConstants.authToken);

  String? get authToken => _authToken.value;
  bool get hasAuthToken => authToken != null;
  UserProfile? get currentUser => _currentUser.value;
  String? get currentUserId => currentUser?.id;

  void setAuthToken(String? token) {
    _authToken.value = (token == null || token.isEmpty) ? null : token;
    notifyListeners();
  }

  void setCurrentUser(UserProfile user) {
    _currentUser.value = user;
    cacheUsers(<UserProfile>[user]);
    notifyListeners();
  }

  void cacheUsers(Iterable<UserProfile> users) {
    final Map<String, UserProfile> updated = <String, UserProfile>{
      ..._knownUsers.value,
    };

    for (final UserProfile user in users) {
      updated[user.id] = user;
    }

    _knownUsers.value = updated;
    notifyListeners();
  }

  UserProfile? userById(String userId) => _knownUsers.value[userId];

  void clear() {
    _authToken.value = null;
    _currentUser.value = null;
    _knownUsers.value = <String, UserProfile>{};
    notifyListeners();
  }
}
