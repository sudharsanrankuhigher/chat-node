import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../core/models/connection_request.dart';
import '../../../core/services/api_service.dart';

class ConnectionsViewModel extends BaseViewModel {
  final ApiService _apiService = locator<ApiService>();

  List<ConnectionRequest> pendingRequests = <ConnectionRequest>[];
  List<ConnectionRequest> invitedRequests = <ConnectionRequest>[];
  bool showPending = true;
  String? errorMessage;

  Future<void> initialise() async {
    await refresh();
  }

  Future<void> refresh() async {
    try {
      setBusy(true);
      errorMessage = null;
      pendingRequests = await _apiService.getPendingRequests();
      invitedRequests = await _apiService.getInvitedRequests();
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  void toggle(bool pending) {
    showPending = pending;
    notifyListeners();
  }

  Future<void> accept(String connectionId) async {
    await _apiService.acceptConnectionRequest(connectionId);
    await refresh();
  }

  Future<void> cancel(String connectionId) async {
    await _apiService.cancelConnectionRequest(connectionId);
    await refresh();
  }
}
