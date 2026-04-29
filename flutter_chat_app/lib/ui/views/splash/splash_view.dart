import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../get_started/get_started_view.dart';
import '../home/home_view.dart';
import 'splash_viewmodel.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SplashViewModel>.nonReactive(
      viewModelBuilder: SplashViewModel.new,
      onViewModelReady: (SplashViewModel viewModel) async {
        final bool hasSession = await viewModel.initialise();
        if (!context.mounted) {
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => hasSession ? const HomeView() : const GetStartedView(),
          ),
        );
      },
      builder: (BuildContext context, SplashViewModel viewModel, Widget? child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFF9054FF), Color(0xFF8B3DFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(
              child: Text(
                'HeartBeat',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFCF4B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
