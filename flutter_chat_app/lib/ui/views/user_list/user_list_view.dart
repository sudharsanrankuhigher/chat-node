import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../core/models/user_list_item.dart';
import '../../widgets/user_action_tile.dart';
import '../call/call_view.dart';
import '../chat/chat_view.dart';
import 'user_list_viewmodel.dart';

class UserListView extends StatelessWidget {
  const UserListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<UserListViewModel>.reactive(
      viewModelBuilder: UserListViewModel.new,
      onViewModelReady: (UserListViewModel viewModel) => viewModel.initialise(),
      builder: (BuildContext context, UserListViewModel viewModel, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Users'),
            actions: <Widget>[
              IconButton(
                onPressed: viewModel.isRefreshing ? null : viewModel.refreshData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _buildBody(context, viewModel),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, UserListViewModel viewModel) {
    if (!viewModel.hasAuthToken) {
      return const _MessageState(
        title: 'Missing auth token',
        subtitle: 'Run the app with --dart-define=AUTH_TOKEN=your_jwt_token',
      );
    }

    if (viewModel.isBusy && viewModel.currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && viewModel.users.isEmpty) {
      return _MessageState(
        title: 'Could not load users',
        subtitle: viewModel.errorMessage!,
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (viewModel.currentUser != null)
            Card(
              child: ListTile(
                title: Text(viewModel.currentUser!.displayName),
                subtitle: Text(viewModel.currentUser!.mobile),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: viewModel.isSocketConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(viewModel.isSocketConnected ? 'Socket connected' : 'Socket offline'),
                  ],
                ),
              ),
            ),
          if (viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                viewModel.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Connections',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (viewModel.connectedUsers.isEmpty)
            const _MessageState(
              title: 'No accepted connections yet',
              subtitle: 'Accepted users will appear here for chat and calls.',
            )
          else
            ...viewModel.connectedUsers.map(
              (UserListItem item) => Card(
                child: ListTile(
                  title: Text(item.user.displayName),
                  subtitle: Text(item.user.mobile),
                  leading: Icon(
                    Icons.circle,
                    size: 14,
                    color: item.isOnline ? Colors.green : Colors.grey,
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: <Widget>[
                      IconButton.filledTonal(
                        onPressed: () => _openChat(context, viewModel, item),
                        icon: const Icon(Icons.chat_bubble_outline),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => _openCall(
                          context,
                          viewModel,
                          item,
                          false,
                        ),
                        icon: const Icon(Icons.call),
                      ),
                      IconButton.filled(
                        onPressed: () => _openCall(
                          context,
                          viewModel,
                          item,
                          true,
                        ),
                        icon: const Icon(Icons.videocam),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'All Users',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...viewModel.users.map(
            (UserListItem item) => UserActionTile(
              item: item,
              onRequest: () => viewModel.sendRequest(item),
              onAccept: () => viewModel.acceptRequest(item),
              onChat: () => _openChat(context, viewModel, item),
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(
    BuildContext context,
    UserListViewModel viewModel,
    UserListItem item,
  ) {
    final currentUser = viewModel.currentUser;
    if (currentUser == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatView(
          currentUser: currentUser,
          peerUser: item.user,
        ),
      ),
    );
  }

  void _openCall(
    BuildContext context,
    UserListViewModel viewModel,
    UserListItem item,
    bool isVideoCall,
  ) {
    final currentUser = viewModel.currentUser;
    if (currentUser == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CallView(
          currentUser: currentUser,
          peerUser: item.user,
          isIncoming: false,
          isVideoCall: isVideoCall,
          autoStart: true,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
