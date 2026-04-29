import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../core/services/api_service.dart';

class OtpViewModel extends BaseViewModel {
  OtpViewModel({required this.mobile});

  final String mobile;
  final TextEditingController otpController = TextEditingController();
  String? errorMessage;

  final ApiService _apiService = locator<ApiService>();

  Future<bool> verifyOtp() async {
    final String otp = otpController.text.trim();
    if (otp.length < 4) {
      errorMessage = 'Enter a valid OTP.';
      notifyListeners();
      return false;
    }

    try {
      errorMessage = null;
      setBusy(true);
      await _apiService.verifyOtp(mobile: mobile, otp: otp);
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
    otpController.dispose();
    super.dispose();
  }
}
