import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/socket_service.dart';

class ChatsViewModel extends ReactiveViewModel {
  final ApiService _apiService = locator<ApiService>();
  final SessionService _sessionService = locator<SessionService>();
  final SocketService _socketService = locator<SocketService>();

  List<UserProfile> _connections = <UserProfile>[];
  String? _errorMessage;

  @override
  List<ListenableServiceMixin> get listenableServices =>
      <ListenableServiceMixin>[_sessionService, _socketService];

  List<UserProfile> get connections => _connections;
  String? get errorMessage => _errorMessage;

  Future<void> initialise() async {
    if (_connections.isNotEmpty) {
      return;
    }

    await refresh();
  }

  Future<void> refresh() async {
    try {
      setBusy(true);
      _errorMessage = null;
      _connections = await _apiService.getConnections();
      _sessionService.cacheUsers(_connections);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      setBusy(false);
    }
  }

  bool isOnline(String userId) => _socketService.onlineUsers.contains(userId);
}
