import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/socket_service.dart';

class ProfileViewModel extends ReactiveViewModel {
  final SessionService _sessionService = locator<SessionService>();
  final SocketService _socketService = locator<SocketService>();

  @override
  List<ListenableServiceMixin> get listenableServices =>
      <ListenableServiceMixin>[_sessionService];

  get currentUser => _sessionService.currentUser;

  void signOut() {
    _socketService.disconnect();
    _sessionService.clear();
  }
}
