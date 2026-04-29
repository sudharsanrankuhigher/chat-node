import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../core/services/api_service.dart';

class WalletViewModel extends BaseViewModel {
  final ApiService _apiService = locator<ApiService>();

  num balance = 0;
  String? errorMessage;

  Future<void> initialise() async {
    await refresh();
  }

  Future<void> refresh() async {
    try {
      setBusy(true);
      balance = await _apiService.getWalletBalance();
      errorMessage = null;
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  Future<void> addMoney() async {
    try {
      setBusy(true);
      balance = await _apiService.addMoney(500);
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }
}
