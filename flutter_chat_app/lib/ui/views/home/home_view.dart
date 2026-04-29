import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../widgets/global_call_listener.dart';
import '../chats/chats_view.dart';
import '../profile/profile_view.dart';
import '../user_list/user_list_view.dart';
import '../wallet/wallet_view.dart';
import 'home_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: HomeViewModel.new,
      builder: (BuildContext context, HomeViewModel viewModel, Widget? child) {
        final List<Widget> pages = <Widget>[
          const UserListView(),
          const ChatsView(),
          const WalletView(),
          const ProfileView(),
        ];

        return GlobalCallListener(
          child: Scaffold(
            body: IndexedStack(
              index: viewModel.currentIndex,
              children: pages,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: viewModel.currentIndex,
              onDestinationSelected: viewModel.setIndex,
              destinations: const <NavigationDestination>[
                NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
                NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
                NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
              ],
            ),
          ),
        );
      },
    );
  }
}
