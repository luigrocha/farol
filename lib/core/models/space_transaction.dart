// lib/core/models/space_transaction.dart
// Transactions inside a Space, with per-member split shares.

import 'package:flutter/foundation.dart';
import 'space.dart';

// ─────────────────────────────────────────────────────────────────
// SpaceCategory
// ─────────────────────────────────────────────────────────────────

@immutable
class SpaceCategory {
  final String id;
  final String spaceId;
  final String name;
  final String? icon;
  final String? color;
  final String financialType; // 'expense' | 'income' | 'transfer'
  final int sortOrder;
  final String? createdBy;
  final DateTime createdAt;

  const SpaceCategory({
    required this.id,
    required this.spaceId,
    required this.name,
    this.icon,
    this.color,
    this.financialType = 'expense',
    this.sortOrder = 0,
    this.createdBy,
    required this.createdAt,
  });

  factory SpaceCategory.fromJson(Map<String, dynamic> json) => SpaceCategory(
        id: json['id'] as String,
        spaceId: json['space_id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
        financialType: (json['financial_type'] as String?) ?? 'expense',
        sortOrder: (json['sort_order'] as int?) ?? 0,
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'space_id': spaceId,
        'name': name,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        'financial_type': financialType,
        'sort_order': sortOrder,
        if (createdBy != null) 'created_by': createdBy,
      };
}

// ─────────────────────────────────────────────────────────────────
// SpaceTransactionShare
// One row per participant per transaction.
// ─────────────────────────────────────────────────────────────────

@immutable
class SpaceTransactionShare {
  final String id;
  final String transactionId;
  final String userId;
  final double amount;
  final bool ledgerLinked;
  final bool settled;
  final DateTime? settledAt;
  final DateTime createdAt;

  const SpaceTransactionShare({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.amount,
    this.ledgerLinked = false,
    this.settled = false,
    this.settledAt,
    required this.createdAt,
  });

  factory SpaceTransactionShare.fromJson(Map<String, dynamic> json) =>
      SpaceTransactionShare(
        id: json['id'] as String,
        transactionId: json['transaction_id'] as String,
        userId: json['user_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        ledgerLinked: (json['ledger_linked'] as bool?) ?? false,
        settled: (json['settled'] as bool?) ?? false,
        settledAt: json['settled_at'] != null
            ? DateTime.parse(json['settled_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'transaction_id': transactionId,
        'user_id': userId,
        'amount': amount,
        'ledger_linked': ledgerLinked,
        'settled': settled,
      };

  SpaceTransactionShare copyWith({bool? ledgerLinked, bool? settled}) =>
      SpaceTransactionShare(
        id: id,
        transactionId: transactionId,
        userId: userId,
        amount: amount,
        ledgerLinked: ledgerLinked ?? this.ledgerLinked,
        settled: settled ?? this.settled,
        settledAt: settledAt,
        createdAt: createdAt,
      );
}

// ─────────────────────────────────────────────────────────────────
// SpaceTransaction
// ─────────────────────────────────────────────────────────────────

@immutable
class SpaceTransaction {
  final String id;
  final String spaceId;
  final String? categoryId;
  final String paidBy;
  final double amount;
  final String description;
  final DateTime date;
  final SplitRule splitRule;
  final String? notes;
  final String? receiptUrl;
  final DateTime? lockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Eagerly loaded when fetched with shares
  final List<SpaceTransactionShare> shares;

  // Optional: eagerly loaded category name for display
  final String? categoryName;
  final String? categoryIcon;

  const SpaceTransaction({
    required this.id,
    required this.spaceId,
    this.categoryId,
    required this.paidBy,
    required this.amount,
    this.description = '',
    required this.date,
    this.splitRule = SplitRule.equal,
    this.notes,
    this.receiptUrl,
    this.lockedAt,
    required this.createdAt,
    required this.updatedAt,
    this.shares = const [],
    this.categoryName,
    this.categoryIcon,
  });

  bool get isLocked => lockedAt != null;

  /// Returns the share amount for a specific user. Returns 0 if not a participant.
  double shareFor(String userId) =>
      shares
          .where((s) => s.userId == userId)
          .map((s) => s.amount)
          .firstOrNull ??
      0;

  factory SpaceTransaction.fromJson(Map<String, dynamic> json) {
    final sharesRaw = json['space_transaction_shares'] as List<dynamic>? ?? [];
    final cat = json['space_categories'] as Map<String, dynamic>?;
    return SpaceTransaction(
      id: json['id'] as String,
      spaceId: json['space_id'] as String,
      categoryId: json['category_id'] as String?,
      paidBy: json['paid_by'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: (json['description'] as String?) ?? '',
      date: DateTime.parse(json['date'] as String),
      splitRule: SplitRuleX.parse(json['split_rule'] as String?),
      notes: json['notes'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      lockedAt: json['locked_at'] != null
          ? DateTime.parse(json['locked_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      shares: sharesRaw
          .map((s) => SpaceTransactionShare.fromJson(s as Map<String, dynamic>))
          .toList(),
      categoryName: cat?['name'] as String?,
      categoryIcon: cat?['icon'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'space_id': spaceId,
        if (categoryId != null) 'category_id': categoryId,
        'paid_by': paidBy,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String().split('T').first,
        'split_rule': splitRule.name,
        if (notes != null) 'notes': notes,
        if (receiptUrl != null) 'receipt_url': receiptUrl,
      };
}

// ─────────────────────────────────────────────────────────────────
// SpaceSettlement
// Net amount one member owes another in a Space.
// ─────────────────────────────────────────────────────────────────

@immutable
class SpaceSettlement {
  final String id;
  final String spaceId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? settledAt;
  final String? settledBy;
  final String? notes;
  final DateTime createdAt;

  const SpaceSettlement({
    required this.id,
    required this.spaceId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.periodStart,
    this.periodEnd,
    this.settledAt,
    this.settledBy,
    this.notes,
    required this.createdAt,
  });

  bool get isPending => settledAt == null;
  bool get isSettled => settledAt != null;

  factory SpaceSettlement.fromJson(Map<String, dynamic> json) =>
      SpaceSettlement(
        id: json['id'] as String,
        spaceId: json['space_id'] as String,
        fromUserId: json['from_user_id'] as String,
        toUserId: json['to_user_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        periodStart: json['period_start'] != null
            ? DateTime.parse(json['period_start'] as String)
            : null,
        periodEnd: json['period_end'] != null
            ? DateTime.parse(json['period_end'] as String)
            : null,
        settledAt: json['settled_at'] != null
            ? DateTime.parse(json['settled_at'] as String)
            : null,
        settledBy: json['settled_by'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

// ─────────────────────────────────────────────────────────────────
// LedgerContribution
// Private bridge: a space share that the user has linked to their
// personal ledger analysis. RLS: user_id = auth.uid() only.
// ─────────────────────────────────────────────────────────────────

@immutable
class LedgerContribution {
  final String id;
  final String userId;
  final String spaceId;
  final String shareId;
  final String? ledgerCategoryId;
  final double amount;
  final DateTime date;
  final DateTime createdAt;

  // Eagerly loaded for display in Personal Ledger
  final String? spaceName;
  final String? spaceEmoji;

  const LedgerContribution({
    required this.id,
    required this.userId,
    required this.spaceId,
    required this.shareId,
    this.ledgerCategoryId,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.spaceName,
    this.spaceEmoji,
  });

  factory LedgerContribution.fromJson(Map<String, dynamic> json) {
    final space = json['spaces'] as Map<String, dynamic>?;
    return LedgerContribution(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      spaceId: json['space_id'] as String,
      shareId: json['share_id'] as String,
      ledgerCategoryId: json['ledger_category_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      spaceName: space?['name'] as String?,
      spaceEmoji: space?['emoji'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'space_id': spaceId,
        'share_id': shareId,
        if (ledgerCategoryId != null) 'ledger_category_id': ledgerCategoryId,
        'amount': amount,
        'date': date.toIso8601String().split('T').first,
      };
}

// ─────────────────────────────────────────────────────────────────
// PersonalLedger
// 1:1 with auth.users. The user's private financial container.
// ─────────────────────────────────────────────────────────────────

@immutable
class PersonalLedger {
  final String id;
  final String userId;
  final String currency;
  final int cutoffDay;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PersonalLedger({
    required this.id,
    required this.userId,
    this.currency = 'BRL',
    this.cutoffDay = 5,
    this.settings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory PersonalLedger.fromJson(Map<String, dynamic> json) => PersonalLedger(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        currency: (json['currency'] as String?) ?? 'BRL',
        cutoffDay: (json['cutoff_day'] as int?) ?? 5,
        settings: (json['settings'] as Map<String, dynamic>?) ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toUpdateJson() => {
        'currency': currency,
        'cutoff_day': cutoffDay,
        'settings': settings,
      };

  PersonalLedger copyWith(
          {String? currency, int? cutoffDay, Map<String, dynamic>? settings}) =>
      PersonalLedger(
        id: id,
        userId: userId,
        currency: currency ?? this.currency,
        cutoffDay: cutoffDay ?? this.cutoffDay,
        settings: settings ?? this.settings,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

// ─────────────────────────────────────────────────────────────────
// MemberBalance
// Computed view — not a DB table. Used in settlement screen.
// ─────────────────────────────────────────────────────────────────

@immutable
class MemberBalance {
  final String userId;
  final double totalPaid; // sum of transactions paid by this user
  final double totalOwed; // sum of shares attributed to this user
  final double net; // positive = others owe them; negative = they owe others

  const MemberBalance({
    required this.userId,
    required this.totalPaid,
    required this.totalOwed,
  }) : net = totalPaid - totalOwed;
}

// ─────────────────────────────────────────────────────────────────
// SettlementSuggestion
// Output of the Splitwise simplification algorithm.
// ─────────────────────────────────────────────────────────────────

@immutable
class SettlementSuggestion {
  final String fromUserId;
  final String toUserId;
  final double amount;

  const SettlementSuggestion({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}
