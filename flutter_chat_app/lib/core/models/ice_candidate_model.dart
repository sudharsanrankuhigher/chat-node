class IceCandidateModel {
  const IceCandidateModel({
    required this.from,
    required this.to,
    required this.candidate,
  });

  final String from;
  final String to;
  final Map<String, dynamic> candidate;

  factory IceCandidateModel.fromMap(Map<String, dynamic> map) {
    return IceCandidateModel(
      from: (map['from'] ?? '').toString(),
      to: (map['to'] ?? '').toString(),
      candidate: Map<String, dynamic>.from(
        (map['candidate'] ?? const <String, dynamic>{}) as Map,
      ),
    );
  }
}
