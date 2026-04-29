import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'wallet_viewmodel.dart';

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<WalletViewModel>.reactive(
      viewModelBuilder: WalletViewModel.new,
      onViewModelReady: (WalletViewModel viewModel) => viewModel.initialise(),
      builder: (BuildContext context, WalletViewModel viewModel, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Wallet')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text('Wallet Balance'),
                            const SizedBox(height: 8),
                            Text(
                              '₹${viewModel.balance}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                        FilledButton.icon(
                          onPressed: viewModel.isBusy ? null : viewModel.addMoney,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Money'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
