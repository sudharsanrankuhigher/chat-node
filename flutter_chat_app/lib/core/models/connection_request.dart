import 'user_profile.dart';

class ConnectionRequest {
  const ConnectionRequest({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.status,
    this.createdAt,
  });

  final String id;
  final UserProfile sender;
  final UserProfile receiver;
  final String status;
  final DateTime? createdAt;

  factory ConnectionRequest.fromJson(Map<String, dynamic> json) {
    return ConnectionRequest(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      sender: UserProfile.fromJson(
        Map<String, dynamic>.from((json['sender'] ?? const <String, dynamic>{}) as Map),
      ),
      receiver: UserProfile.fromJson(
        Map<String, dynamic>.from((json['receiver'] ?? const <String, dynamic>{}) as Map),
      ),
      status: (json['status'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}
