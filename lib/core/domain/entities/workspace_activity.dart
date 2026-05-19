/// A single entry in the workspace activity feed.
class WorkspaceActivity {
  final String id;
  final String workspaceId;
  final String userId; // who performed the action
  final String action;
  // 'added_expense' | 'deleted_expense'
  // 'added_recurring' | 'deleted_recurring'
  // 'added_installment' | 'deleted_installment'
  final String entityType;
  final String? entityId;
  final String? entityLabel; // denormalized: store name or category
  final double? amount;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const WorkspaceActivity({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.entityLabel,
    this.amount,
    this.metadata = const {},
    required this.createdAt,
  });

  factory WorkspaceActivity.fromJson(Map<String, dynamic> json) =>
      WorkspaceActivity(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String,
        userId: json['user_id'] as String,
        action: json['action'] as String,
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String?,
        entityLabel: json['entity_label'] as String?,
        amount: (json['amount'] as num?)?.toDouble(),
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  // ── Convenience getters ──────────────────────────────────────────────────

  bool get isAddedExpense => action == 'added_expense';
  bool get isDeletedExpense => action == 'deleted_expense';
  bool get isAddedRecurring => action == 'added_recurring';
  bool get isDeletedRecurring => action == 'deleted_recurring';
  bool get isAddedInstallment => action == 'added_installment';
  bool get isDeletedInstallment => action == 'deleted_installment';

  bool get isAddition => action.startsWith('added_');
  bool get isDeletion => action.startsWith('deleted_');

  /// Human-readable action verb for the feed tile.
  String actionLabel({required bool isSelf}) {
    final subject = isSelf ? 'Você' : null;
    return switch (action) {
      'added_expense' => '${subject ?? 'adicionou'} uma despesa',
      'deleted_expense' => '${subject ?? 'removeu'} uma despesa',
      'added_recurring' => '${subject ?? 'adicionou'} recorrência',
      'deleted_recurring' => '${subject ?? 'removeu'} recorrência',
      'added_installment' => '${subject ?? 'adicionou'} parcelamento',
      'deleted_installment' => '${subject ?? 'removeu'} parcelamento',
      _ => action,
    };
  }
}
