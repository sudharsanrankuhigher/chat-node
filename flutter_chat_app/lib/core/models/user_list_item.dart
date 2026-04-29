import 'connection_request.dart';
import 'user_profile.dart';
import 'user_relationship_status.dart';

class UserListItem {
  const UserListItem({
    required this.user,
    required this.status,
    this.request,
    this.isOnline = false,
  });

  final UserProfile user;
  final UserRelationshipStatus status;
  final ConnectionRequest? request;
  final bool isOnline;

  bool get canChatOrCall => status == UserRelationshipStatus.connected;
  bool get canAccept => status == UserRelationshipStatus.requestReceived;
  bool get isPending => status == UserRelationshipStatus.requestSent;
}
