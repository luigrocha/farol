enum NotificationType {
  workspaceInvite,
  inviteAccepted,
  inviteDeclined,
  unknown;

  static NotificationType fromString(String s) => switch (s) {
        'workspace_invite' => workspaceInvite,
        'invite_accepted' => inviteAccepted,
        'invite_declined' => inviteDeclined,
        _ => unknown,
      };
}

class UserNotification {
  const UserNotification({
    required this.id,
    required this.type,
    required this.notificationType,
    required this.payload,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final NotificationType notificationType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  // ── workspace_invite helpers ──────────────────────────────────────────────
  String get inviteToken => payload['invite_token'] as String? ?? '';
  String get workspaceName => payload['workspace_name'] as String? ?? '';
  String get invitedByName =>
      payload['invited_by_name'] as String? ?? 'Someone';
  String get role => payload['role'] as String? ?? 'member';

  // ── invite_accepted / invite_declined helpers ─────────────────────────────
  String get inviteeName => payload['invitee_name'] as String? ?? 'Someone';
  String get inviteeEmail => payload['invitee_email'] as String? ?? '';

  factory UserNotification.fromJson(Map<String, dynamic> json) =>
      UserNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        notificationType: NotificationType.fromString(json['type'] as String),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['created_at'] as String),
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'] as String)
            : null,
      );
}
