import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../login/login_view.dart';
import 'get_started_viewmodel.dart';

class GetStartedView extends StatelessWidget {
  const GetStartedView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<GetStartedViewModel>.nonReactive(
      viewModelBuilder: GetStartedViewModel.new,
      builder: (BuildContext context, GetStartedViewModel viewModel, Widget? child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFF8C53FF), Color(0xFF9B5EFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: <Widget>[
                    const Spacer(),
                    const Text(
                      'Voice & Video Calls',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Start calls instantly and enjoy real-time chats',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF8C53FF),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => const LoginView(),
                            ),
                          );
                        },
                        child: const Text('Get started'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
