class CallSignal {
  const CallSignal({
    required this.from,
    required this.to,
    required this.description,
  });

  final String from;
  final String to;
  final Map<String, dynamic> description;

  factory CallSignal.fromMap(Map<String, dynamic> map) {
    return CallSignal(
      from: (map['from'] ?? '').toString(),
      to: (map['to'] ?? '').toString(),
      description: Map<String, dynamic>.from(
        (map['offer'] ?? map['answer'] ?? const <String, dynamic>{}) as Map,
      ),
    );
  }
}
