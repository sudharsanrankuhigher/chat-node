class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage.fromJson(map);
  }

  factory ChatMessage.fromJson(Map<String, dynamic> map) {
    return ChatMessage(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      senderId: _extractUserId(map['senderId'] ?? map['sender']),
      receiverId: _extractUserId(map['receiverId'] ?? map['receiver']),
      message: (map['message'] ?? '').toString(),
      timestamp: map['timestamp'] == null && map['createdAt'] == null
          ? DateTime.now()
          : DateTime.tryParse(
                (map['timestamp'] ?? map['createdAt']).toString(),
              ) ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static String _extractUserId(dynamic rawValue) {
    if (rawValue is Map<String, dynamic>) {
      return (rawValue['_id'] ?? rawValue['id'] ?? '').toString();
    }

    if (rawValue is Map) {
      return (rawValue['_id'] ?? rawValue['id'] ?? '').toString();
    }

    return (rawValue ?? '').toString();
  }
}
