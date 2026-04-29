import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../home/home_view.dart';
import 'otp_viewmodel.dart';

class OtpView extends StatelessWidget {
  const OtpView({
    super.key,
    required this.mobile,
  });

  final String mobile;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<OtpViewModel>.reactive(
      viewModelBuilder: () => OtpViewModel(mobile: mobile),
      builder: (BuildContext context, OtpViewModel viewModel, Widget? child) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 32),
                  Text(
                    'Enter Code',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text('We\'ve sent a verification code to $mobile.'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: viewModel.otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: const InputDecoration(
                      hintText: 'Enter OTP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (viewModel.errorMessage != null)
                    Text(
                      viewModel.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: viewModel.isBusy
                          ? null
                          : () async {
                              final bool verified = await viewModel.verifyOtp();
                              if (!context.mounted || !verified) {
                                return;
                              }

                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute<void>(
                                  builder: (_) => const HomeView(),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            },
                      child: Text(viewModel.isBusy ? 'Verifying...' : 'Verify'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
