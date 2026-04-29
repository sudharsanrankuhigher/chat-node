import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';

class EditProfileViewModel extends BaseViewModel {
  final ApiService _apiService = locator<ApiService>();
  final SessionService _sessionService = locator<SessionService>();

  late final TextEditingController nameController = TextEditingController(
    text: _sessionService.currentUser?.name ?? '',
  );

  Future<bool> save() async {
    try {
      setBusy(true);
      await _apiService.updateProfile(name: nameController.text.trim());
      return true;
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}
