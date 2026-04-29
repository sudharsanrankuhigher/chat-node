import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../otp/otp_view.dart';
import 'login_viewmodel.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<LoginViewModel>.reactive(
      viewModelBuilder: LoginViewModel.new,
      builder: (BuildContext context, LoginViewModel viewModel, Widget? child) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Spacer(),
                  Text(
                    'Start Connecting',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: viewModel.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: viewModel.mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+91 90000 00000',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (viewModel.errorMessage != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      viewModel.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: viewModel.isBusy
                          ? null
                          : () async {
                              final bool sent = await viewModel.sendOtp();
                              if (!context.mounted || !sent) {
                                return;
                              }

                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => OtpView(
                                    mobile: viewModel.mobileController.text.trim(),
                                  ),
                                ),
                              );
                            },
                      child: Text(viewModel.isBusy ? 'Sending...' : 'Continue'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'By clicking, I accept the Terms & Conditions & Privacy Policy.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
