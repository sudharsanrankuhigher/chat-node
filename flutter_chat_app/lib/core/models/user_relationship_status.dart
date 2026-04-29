enum UserRelationshipStatus {
  self,
  notConnected,
  requestSent,
  requestReceived,
  connected,
}

extension UserRelationshipStatusX on UserRelationshipStatus {
  String get label {
    switch (this) {
      case UserRelationshipStatus.self:
        return 'You';
      case UserRelationshipStatus.notConnected:
        return 'Not connected';
      case UserRelationshipStatus.requestSent:
        return 'Pending';
      case UserRelationshipStatus.requestReceived:
        return 'Request received';
      case UserRelationshipStatus.connected:
        return 'Connected';
    }
  }
}
