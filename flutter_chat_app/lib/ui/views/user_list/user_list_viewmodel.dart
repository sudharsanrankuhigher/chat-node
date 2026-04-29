import 'package:stacked/stacked.dart';

import '../../../core/models/connection_request.dart';
import '../../../core/models/user_list_item.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/user_relationship_status.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../app/app.locator.dart';

class UserListViewModel extends ReactiveViewModel {
  final ApiService _apiService = locator<ApiService>();
  final SessionService _sessionService = locator<SessionService>();
  final SocketService _socketService = locator<SocketService>();

  bool _initialized = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  List<UserListItem> _users = <UserListItem>[];

  @override
  List<ListenableServiceMixin> get listenableServices =>
      <ListenableServiceMixin>[_sessionService, _socketService];

  bool get hasAuthToken => _sessionService.hasAuthToken;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  UserProfile? get currentUser => _sessionService.currentUser;
  bool get isSocketConnected => _socketService.isConnected;
  List<UserListItem> get users => _users.map(_applyOnlineState).toList();
  List<UserListItem> get connectedUsers => users
      .where((UserListItem item) => item.status == UserRelationshipStatus.connected)
      .toList();

  Future<void> initialise() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    await _bootstrap();
  }

  Future<void> refreshData() => _loadAllData(showBusy: false);

  Future<void> sendRequest(UserListItem item) async {
    await runBusyFuture(_apiService.sendConnectionRequest(item.user.id));
    await refreshData();
  }

  Future<void> acceptRequest(UserListItem item) async {
    final String? connectionId = item.request?.id;
    if (connectionId == null || connectionId.isEmpty) {
      return;
    }

    await runBusyFuture(_apiService.acceptConnectionRequest(connectionId));
    await refreshData();
  }

  Future<void> _bootstrap() async {
    if (!hasAuthToken) {
      _errorMessage = 'AUTH_TOKEN is missing. Run the app with --dart-define=AUTH_TOKEN=...';
      notifyListeners();
      return;
    }

    await _loadAllData(showBusy: true);
  }

  Future<void> _loadAllData({required bool showBusy}) async {
    _errorMessage = null;
    _isRefreshing = !showBusy;
    if (_isRefreshing) {
      notifyListeners();
    } else {
      setBusy(true);
    }

    try {
      final UserProfile profile = await _apiService.getProfile();
      _sessionService.setCurrentUser(profile);

      await _socketService.connect(profile.id);

      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        _apiService.getUsers(),
        _apiService.getConnections(),
        _apiService.getPendingRequests(),
        _apiService.getInvitedRequests(),
      ]);

      final List<UserProfile> allUsers = results[0] as List<UserProfile>;
      final List<UserProfile> connections = results[1] as List<UserProfile>;
      final List<ConnectionRequest> pendingRequests = results[2] as List<ConnectionRequest>;
      final List<ConnectionRequest> invitedRequests = results[3] as List<ConnectionRequest>;

      _sessionService.cacheUsers(<UserProfile>[
        ...allUsers,
        ...connections,
        ...pendingRequests.map((ConnectionRequest request) => request.sender),
        ...pendingRequests.map((ConnectionRequest request) => request.receiver),
        ...invitedRequests.map((ConnectionRequest request) => request.sender),
        ...invitedRequests.map((ConnectionRequest request) => request.receiver),
      ]);

      _users = _mergeUserStates(
        currentUserId: profile.id,
        allUsers: allUsers,
        connections: connections,
        pendingRequests: pendingRequests,
        invitedRequests: invitedRequests,
        onlineUserIds: _socketService.onlineUsers.toSet(),
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isRefreshing = false;
      if (showBusy) {
        setBusy(false);
      } else {
        notifyListeners();
      }
    }
  }

  List<UserListItem> _mergeUserStates({
    required String currentUserId,
    required List<UserProfile> allUsers,
    required List<UserProfile> connections,
    required List<ConnectionRequest> pendingRequests,
    required List<ConnectionRequest> invitedRequests,
    required Set<String> onlineUserIds,
  }) {
    final Map<String, UserProfile> userMap = <String, UserProfile>{
      for (final UserProfile user in allUsers) user.id: user,
    };
    final Set<String> connectedIds = connections.map((UserProfile user) => user.id).toSet();
    final Map<String, ConnectionRequest> incomingBySender = <String, ConnectionRequest>{
      for (final ConnectionRequest request in pendingRequests) request.sender.id: request,
    };
    final Map<String, ConnectionRequest> outgoingByReceiver = <String, ConnectionRequest>{
      for (final ConnectionRequest request in invitedRequests)
        if (request.status.toLowerCase() == 'pending') request.receiver.id: request,
    };

    final List<UserListItem> items = userMap.values
        .where((UserProfile user) => user.id != currentUserId)
        .map((UserProfile user) {
      if (connectedIds.contains(user.id)) {
        return UserListItem(
          user: user,
          status: UserRelationshipStatus.connected,
          isOnline: onlineUserIds.contains(user.id),
        );
      }

      if (incomingBySender.containsKey(user.id)) {
        return UserListItem(
          user: user,
          status: UserRelationshipStatus.requestReceived,
          request: incomingBySender[user.id],
          isOnline: onlineUserIds.contains(user.id),
        );
      }

      if (outgoingByReceiver.containsKey(user.id)) {
        return UserListItem(
          user: user,
          status: UserRelationshipStatus.requestSent,
          request: outgoingByReceiver[user.id],
          isOnline: onlineUserIds.contains(user.id),
        );
      }

      return UserListItem(
        user: user,
        status: UserRelationshipStatus.notConnected,
        isOnline: onlineUserIds.contains(user.id),
      );
    }).toList();

    items.sort(
      (UserListItem a, UserListItem b) =>
          a.user.displayName.toLowerCase().compareTo(b.user.displayName.toLowerCase()),
    );
    return items;
  }

  UserListItem _applyOnlineState(UserListItem item) {
    return UserListItem(
      user: item.user,
      status: item.status,
      request: item.request,
      isOnline: _socketService.onlineUsers.contains(item.user.id),
    );
  }
}
