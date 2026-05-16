// lib/core/domain/entities/space_activity.dart
//
// A single entry in the space activity feed.
// Mirrors WorkspaceActivity but scoped to spaces.
//
// Actions:
//   'added_transaction'    — someone added an expense to the space
//   'deleted_transaction'  — someone deleted an expense from the space
//   'recorded_settlement'  — a settlement was recorded between members

/// A single entry in the space activity feed.
class SpaceActivity {
  final String  id;
  final String  spaceId;
  final String  userId;       // who performed the action
  final String  action;
  final String  entityType;   // 'space_transaction' | 'space_settlement'
  final String? entityId;
  final String? entityLabel;  // denormalized description
  final double? amount;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const SpaceActivity({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.entityLabel,
    this.amount,
    this.metadata = const {},
    required this.createdAt,
  });

  factory SpaceActivity.fromJson(Map<String, dynamic> json) => SpaceActivity(
    id:          json['id'] as String,
    spaceId:     json['space_id'] as String,
    userId:      json['user_id'] as String,
    action:      json['action'] as String,
    entityType:  json['entity_type'] as String,
    entityId:    json['entity_id'] as String?,
    entityLabel: json['entity_label'] as String?,
    amount:      (json['amount'] as num?)?.toDouble(),
    metadata:    (json['metadata'] as Map<String, dynamic>?) ?? {},
    createdAt:   DateTime.parse(json['created_at'] as String),
  );

  // ── Convenience getters ──────────────────────────────────────────────────

  bool get isAddition  => action.startsWith('added_');
  bool get isDeletion  => action.startsWith('deleted_');
  bool get isSettlement => action == 'recorded_settlement';

  /// Human-readable action verb for the feed tile.
  String actionLabel({required bool isSelf}) {
    final you = isSelf ? 'Você' : null;
    return switch (action) {
      'added_transaction'   => you != null ? 'Você adicionou gasto'  : 'adicionou gasto',
      'deleted_transaction' => you != null ? 'Você removeu gasto'    : 'removeu gasto',
      'recorded_settlement' => you != null ? 'Você registrou acerto' : 'registrou acerto',
      _                     => action,
    };
  }
}
