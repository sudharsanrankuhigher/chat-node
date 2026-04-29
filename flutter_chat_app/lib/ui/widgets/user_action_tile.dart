import 'package:flutter/material.dart';

import '../../core/models/user_list_item.dart';
import '../../core/models/user_relationship_status.dart';

class UserActionTile extends StatelessWidget {
  const UserActionTile({
    super.key,
    required this.item,
    required this.onRequest,
    required this.onAccept,
    required this.onChat,
  });

  final UserListItem item;
  final VoidCallback onRequest;
  final VoidCallback onAccept;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            item.user.displayName.isEmpty ? '?' : item.user.displayName[0].toUpperCase(),
          ),
        ),
        title: Text(item.user.displayName),
        subtitle: Text(
          item.user.mobile.isEmpty
              ? item.status.label
              : '${item.user.mobile} • ${item.status.label}',
        ),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Icon(
              Icons.circle,
              size: 12,
              color: item.isOnline ? Colors.green : Colors.grey,
            ),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    switch (item.status) {
      case UserRelationshipStatus.notConnected:
        return FilledButton(
          onPressed: onRequest,
          child: const Text('Request'),
        );
      case UserRelationshipStatus.requestSent:
        return const FilledButton(
          onPressed: null,
          child: Text('Pending'),
        );
      case UserRelationshipStatus.requestReceived:
        return FilledButton(
          onPressed: onAccept,
          child: const Text('Accept'),
        );
      case UserRelationshipStatus.connected:
        return FilledButton(
          onPressed: onChat,
          child: const Text('Chat'),
        );
      case UserRelationshipStatus.self:
        return const SizedBox.shrink();
    }
  }
}
