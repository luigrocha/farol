import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetChange {
  final String id;
  final String workspaceId;
  final String categorySlug;
  final double? oldAmount;
  final double newAmount;
  final String changedBy;
  final DateTime changedAt;

  const BudgetChange({
    required this.id,
    required this.workspaceId,
    required this.categorySlug,
    this.oldAmount,
    required this.newAmount,
    required this.changedBy,
    required this.changedAt,
  });

  factory BudgetChange.fromJson(Map<String, dynamic> json) => BudgetChange(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String,
        categorySlug: json['category_slug'] as String,
        oldAmount: (json['old_amount'] as num?)?.toDouble(),
        newAmount: (json['new_amount'] as num).toDouble(),
        changedBy: json['changed_by'] as String,
        changedAt: DateTime.parse(json['changed_at'] as String),
      );
}

class BudgetChangesRepository {
  final SupabaseClient _supabase;

  const BudgetChangesRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Logs a budget edit for [categorySlug] in [workspaceId].
  Future<void> log({
    required String workspaceId,
    required String categorySlug,
    required double newAmount,
    double? oldAmount,
  }) async {
    final uid = _userId;
    if (uid == null) return;
    await _supabase.from('budget_changes').insert({
      'workspace_id': workspaceId,
      'category_slug': categorySlug,
      'old_amount': oldAmount,
      'new_amount': newAmount,
      'changed_by': uid,
    });
  }

  /// Fetches the most recent change for each category in [workspaceId].
  /// Returns a map from category_slug → BudgetChange.
  Future<Map<String, BudgetChange>> fetchLatestPerCategory(
      String workspaceId) async {
    // Fetch all changes ordered by newest first, then deduplicate by slug
    final rows = await _supabase
        .from('budget_changes')
        .select()
        .eq('workspace_id', workspaceId)
        .order('changed_at', ascending: false)
        .limit(200); // reasonable ceiling — one change per category per day

    final result = <String, BudgetChange>{};
    for (final row in rows) {
      final change = BudgetChange.fromJson(row);
      result.putIfAbsent(change.categorySlug, () => change);
    }
    return result;
  }
}
