import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../connections/connections_view.dart';
import '../edit_profile/edit_profile_view.dart';
import '../login/login_view.dart';
import 'profile_viewmodel.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ProfileViewModel>.reactive(
      viewModelBuilder: ProfileViewModel.new,
      builder: (BuildContext context, ProfileViewModel viewModel, Widget? child) {
        final user = viewModel.currentUser;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (user != null)
                ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    child: Text(user.displayName[0].toUpperCase()),
                  ),
                  title: Text(user.displayName),
                  subtitle: Text(user.mobile),
                ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Personal Information'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EditProfileView(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.group_outlined),
                      title: const Text('Connections'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ConnectionsView(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () {
                  viewModel.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginView(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        );
      },
    );
  }
}
