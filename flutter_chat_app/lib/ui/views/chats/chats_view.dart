import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../core/services/session_service.dart';
import '../../../app/app.locator.dart';
import '../chat/chat_view.dart';
import '../connections/connections_view.dart';
import 'chats_viewmodel.dart';

class ChatsView extends StatelessWidget {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChatsViewModel>.reactive(
      viewModelBuilder: ChatsViewModel.new,
      onViewModelReady: (ChatsViewModel viewModel) => viewModel.initialise(),
      builder: (BuildContext context, ChatsViewModel viewModel, Widget? child) {
        final session = locator<SessionService>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chats'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ConnectionsView(),
                ),
              );
            },
            label: const Text('Requests'),
            icon: const Icon(Icons.add),
          ),
          body: viewModel.isBusy
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.connections.length,
                  itemBuilder: (BuildContext context, int index) {
                    final user = viewModel.connections[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(user.displayName[0].toUpperCase()),
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(viewModel.isOnline(user.id) ? 'Active now' : user.mobile),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: session.currentUser == null
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ChatView(
                                      currentUser: session.currentUser!,
                                      peerUser: user,
                                    ),
                                  ),
                                );
                              },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
