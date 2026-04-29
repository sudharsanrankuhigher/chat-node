class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.mobile,
    this.walletBalance,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String mobile;
  final num? walletBalance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName => name.isEmpty ? mobile : name;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      walletBalance: json['walletBalance'] as num?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  factory UserProfile.fallback(String id) {
    return UserProfile(
      id: id,
      name: 'User $id',
      mobile: '',
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
