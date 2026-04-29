class CallSignal {
  const CallSignal({
    required this.from,
    required this.to,
    required this.callType,
    required this.description,
  });

  final String from;
  final String to;
  final String callType;
  final Map<String, dynamic> description;

  factory CallSignal.fromMap(Map<String, dynamic> map) {
    return CallSignal(
      from: (map['from'] ?? '').toString(),
      to: (map['to'] ?? '').toString(),
      callType: (map['callType'] ?? 'video').toString(),
      description: Map<String, dynamic>.from(
        (map['offer'] ?? map['answer'] ?? const <String, dynamic>{}) as Map,
      ),
    );
  }
}
