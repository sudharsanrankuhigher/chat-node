import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../core/services/api_service.dart';

class LoginViewModel extends BaseViewModel {
  final ApiService _apiService = locator<ApiService>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  String? errorMessage;

  Future<bool> sendOtp() async {
    final String mobile = mobileController.text.trim();
    final String name = nameController.text.trim();

    if (mobile.isEmpty) {
      errorMessage = 'Phone number is required.';
      notifyListeners();
      return false;
    }

    try {
      errorMessage = null;
      setBusy(true);
      await _apiService.sendOtp(
        mobile: mobile,
        name: name.isEmpty ? null : name,
      );
      return true;
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    super.dispose();
  }
}
