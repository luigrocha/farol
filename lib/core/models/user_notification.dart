class UserNotification {
  const UserNotification({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  // Helpers for type == 'workspace_invite'
  String get inviteToken    => payload['invite_token']    as String;
  String get workspaceName  => payload['workspace_name']  as String? ?? '';
  String get invitedByName  => payload['invited_by_name'] as String? ?? 'Someone';
  String get role           => payload['role']            as String? ?? 'member';

  factory UserNotification.fromJson(Map<String, dynamic> json) => UserNotification(
        id:        json['id'] as String,
        type:      json['type'] as String,
        payload:   Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['created_at'] as String),
        readAt:    json['read_at'] != null
            ? DateTime.parse(json['read_at'] as String)
            : null,
      );
}
