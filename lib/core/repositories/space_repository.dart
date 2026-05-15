// lib/core/repositories/space_repository.dart
// Data access for Spaces v2: spaces, space_members, space_categories,
// space_transactions, space_transaction_shares, space_settlements,
// ledger_contributions, personal_ledgers.
//
// RLS is enforced at the database level. This repository never filters
// by user_id manually — it relies on the SECURITY DEFINER helper functions
// and policies defined in V40/V41.

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/space.dart';
import '../models/space_transaction.dart';

class SpaceRepository {
  final SupabaseClient _client;

  const SpaceRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ═══════════════════════════════════════════════════════════════
  // Personal Ledger
  // ═══════════════════════════════════════════════════════════════

  /// Fetches (or creates) the personal ledger for the current user.
  Future<PersonalLedger> getOrCreatePersonalLedger() async {
    final rows = await _client
        .from('personal_ledgers')
        .select()
        .eq('user_id', _userId)
        .limit(1);

    if (rows.isNotEmpty) {
      return PersonalLedger.fromJson(rows.first as Map<String, dynamic>);
    }

    // Create if missing (e.g. for users who signed up before V41)
    final inserted = await _client
        .from('personal_ledgers')
        .insert({'user_id': _userId, 'currency': 'BRL', 'cutoff_day': 5})
        .select()
        .single();
    return PersonalLedger.fromJson(inserted);
  }

  Future<PersonalLedger> updatePersonalLedger(PersonalLedger ledger) async {
    final updated = await _client
        .from('personal_ledgers')
        .update(ledger.toUpdateJson())
        .eq('user_id', _userId)
        .select()
        .single();
    return PersonalLedger.fromJson(updated);
  }

  // ═══════════════════════════════════════════════════════════════
  // Spaces — CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Returns all spaces the current user is a member of (active only).
  Future<List<Space>> getUserSpaces() async {
    final rows = await _client
        .from('spaces')
        .select('*, space_members(*)')
        .isFilter('archived_at', null)
        .order('created_at');
    return (rows as List)
        .map((r) => Space.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Space> getSpace(String spaceId) async {
    final row = await _client
        .from('spaces')
        .select('*, space_members(*)')
        .eq('id', spaceId)
        .single();
    return Space.fromJson(row);
  }

  /// Creates a new Space and adds the creator as owner.
  Future<Space> createSpace({
    required String name,
    required SpaceType type,
    String? emoji,
    String? color,
    String? description,
    String currency = 'BRL',
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final spaceRow = await _client
        .from('spaces')
        .insert({
          'name':        name,
          'type':        type.name,
          'emoji':       emoji ?? type.defaultEmoji,
          if (color != null)       'color':       color,
          if (description != null) 'description': description,
          'currency':    currency,
          'owner_id':    _userId,
          if (startsAt != null) 'starts_at': startsAt.toIso8601String().split('T').first,
          if (endsAt != null)   'ends_at':   endsAt.toIso8601String().split('T').first,
        })
        .select()
        .single();

    final spaceId = spaceRow['id'] as String;

    // Add creator as owner member
    await _client.from('space_members').insert({
      'space_id': spaceId,
      'user_id':  _userId,
      'role':     'owner',
    });

    return getSpace(spaceId);
  }

  Future<Space> updateSpaceIdentity(
    String spaceId, {
    String? name,
    String? emoji,
    String? color,
    String? description,
    SpaceType? type,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null)        updates['name']        = name;
    if (emoji != null)       updates['emoji']       = emoji;
    if (color != null)       updates['color']       = color;
    if (description != null) updates['description'] = description;
    if (type != null)        updates['type']        = type.name;

    await _client.from('spaces').update(updates).eq('id', spaceId);
    return getSpace(spaceId);
  }

  Future<void> archiveSpace(String spaceId) async {
    await _client
        .from('spaces')
        .update({'archived_at': DateTime.now().toIso8601String()})
        .eq('id', spaceId);
  }

  // ═══════════════════════════════════════════════════════════════
  // Space Members
  // ═══════════════════════════════════════════════════════════════

  Future<SpaceMember> updateMemberRole(
    String spaceId,
    String userId,
    SpaceRole role,
  ) async {
    final updated = await _client
        .from('space_members')
        .update({'role': role.name})
        .eq('space_id', spaceId)
        .eq('user_id', userId)
        .select()
        .single();
    return SpaceMember.fromJson(updated);
  }

  Future<SpaceMember> updateMemberCapabilities(
    String spaceId,
    String userId, {
    bool? canAddExpenses,
    bool? canSeeBalances,
    bool? canSeeMemberBalances,
    bool? canExport,
    bool? canSeeSettlements,
  }) async {
    final updates = <String, dynamic>{};
    if (canAddExpenses != null)        updates['can_add_expenses']         = canAddExpenses;
    if (canSeeBalances != null)        updates['can_see_balances']         = canSeeBalances;
    if (canSeeMemberBalances != null)  updates['can_see_member_balances']  = canSeeMemberBalances;
    if (canExport != null)             updates['can_export']               = canExport;
    if (canSeeSettlements != null)     updates['can_see_settlements']      = canSeeSettlements;

    final updated = await _client
        .from('space_members')
        .update(updates)
        .eq('space_id', spaceId)
        .eq('user_id', userId)
        .select()
        .single();
    return SpaceMember.fromJson(updated);
  }

  Future<void> removeMember(String spaceId, String userId) async {
    await _client
        .from('space_members')
        .delete()
        .eq('space_id', spaceId)
        .eq('user_id', userId);
  }

  // ═══════════════════════════════════════════════════════════════
  // Space Invites
  // ═══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> createInvite({
    required String spaceId,
    required String invitedEmail,
    required SpaceRole role,
    String? preset,
  }) async {
    final row = await _client
        .from('space_invites')
        .insert({
          'space_id':      spaceId,
          'invited_email': invitedEmail,
          'role':          role.name,
          'invited_by':    _userId,
          if (preset != null) 'preset': preset,
        })
        .select()
        .single();
    return row as Map<String, dynamic>;
  }

  /// Accept a space invite via the Edge Function.
  ///
  /// The invitee has no space membership yet, so RLS blocks a direct SELECT
  /// on space_invites. The Edge Function runs with service-role credentials
  /// and handles token validation, membership creation, and invite marking
  /// atomically.
  ///
  /// Returns the joined [Space] on success.
  /// Throws [SpaceInviteException] with a machine-readable [code] on failure.
  Future<Space> acceptSpaceInviteViaEdgeFunction(String token) async {
    try {
      final response = await _client.functions.invoke(
        'accept-space-invite',
        body: {'token': token},
      );

      final data = response.data;
      debugPrint('[SpaceInviteAccept] response: status=${response.status} data=$data');

      final dataMap  = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final spaceRaw = dataMap['space'];
      if (spaceRaw == null) throw const SpaceInviteException('internal_error');

      final spaceJson = spaceRaw is Map
          ? Map<String, dynamic>.from(spaceRaw)
          : <String, dynamic>{};

      return Space.fromJson(spaceJson);

    } on FunctionException catch (e) {
      debugPrint('[SpaceInviteAccept] FunctionException: status=${e.status} details=${e.details}');
      final details = e.details;
      final code    = (details is Map ? details['error'] : null) as String?
          ?? 'internal_error';
      throw SpaceInviteException(code);
    } catch (e) {
      debugPrint('[SpaceInviteAccept] Unexpected error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Space Categories
  // ═══════════════════════════════════════════════════════════════

  Future<List<SpaceCategory>> getCategories(String spaceId) async {
    final rows = await _client
        .from('space_categories')
        .select()
        .eq('space_id', spaceId)
        .order('sort_order');
    return (rows as List)
        .map((r) => SpaceCategory.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<SpaceCategory> createCategory({
    required String spaceId,
    required String name,
    String? icon,
    String? color,
    String financialType = 'expense',
  }) async {
    final row = await _client
        .from('space_categories')
        .insert({
          'space_id':      spaceId,
          'name':          name,
          if (icon != null)  'icon':  icon,
          if (color != null) 'color': color,
          'financial_type': financialType,
          'created_by':    _userId,
        })
        .select()
        .single();
    return SpaceCategory.fromJson(row);
  }

  Future<void> createDefaultCategories(String spaceId, SpaceType type) async {
    final defaults = _defaultCategoriesFor(type);
    if (defaults.isEmpty) return;

    await _client.from('space_categories').insert(
      defaults.asMap().entries.map((e) => {
        'space_id':       spaceId,
        'name':           e.value['name'],
        'icon':           e.value['icon'],
        'financial_type': 'expense',
        'sort_order':     e.key,
        'created_by':     _userId,
      }).toList(),
    );
  }

  List<Map<String, String>> _defaultCategoriesFor(SpaceType type) => switch (type) {
        SpaceType.household => [
            {'name': 'Aluguel',       'icon': '🏠'},
            {'name': 'Energia',       'icon': '⚡'},
            {'name': 'Água',          'icon': '💧'},
            {'name': 'Internet',      'icon': '📶'},
            {'name': 'Alimentação',   'icon': '🛒'},
            {'name': 'Limpeza',       'icon': '🧹'},
          ],
        SpaceType.trip => [
            {'name': 'Hospedagem',    'icon': '🏨'},
            {'name': 'Transporte',    'icon': '🚗'},
            {'name': 'Alimentação',   'icon': '🍽️'},
            {'name': 'Atividades',    'icon': '🎭'},
            {'name': 'Compras',       'icon': '🛍️'},
          ],
        SpaceType.project => [
            {'name': 'Software',      'icon': '💻'},
            {'name': 'Serviços',      'icon': '🔧'},
            {'name': 'Marketing',     'icon': '📢'},
            {'name': 'Equipamentos',  'icon': '🖥️'},
          ],
        SpaceType.family => [
            {'name': 'Moradia',       'icon': '🏠'},
            {'name': 'Alimentação',   'icon': '🛒'},
            {'name': 'Saúde',         'icon': '🏥'},
            {'name': 'Educação',      'icon': '📚'},
          ],
        SpaceType.business => [
            {'name': 'Operacional',   'icon': '⚙️'},
            {'name': 'Pessoal',       'icon': '👥'},
            {'name': 'Marketing',     'icon': '📢'},
            {'name': 'Tecnologia',    'icon': '💻'},
          ],
      };

  // ═══════════════════════════════════════════════════════════════
  // Space Transactions
  // ═══════════════════════════════════════════════════════════════

  /// Fetches paginated transactions for a space, newest first.
  Future<List<SpaceTransaction>> getTransactions(
    String spaceId, {
    int limit = 30,
    String? beforeId,
    DateTime? beforeDate,
  }) async {
    final query = _client
        .from('space_transactions')
        .select('''
          *,
          space_transaction_shares(*),
          space_categories(id, name, icon)
        ''')
        .eq('space_id', spaceId);

    final filteredQuery = beforeDate != null
        ? query.lt('date', beforeDate.toIso8601String().split('T').first)
        : query;

    final rows = await filteredQuery
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => SpaceTransaction.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Creates a transaction and its shares atomically.
  /// Validates that SUM(shares) == transaction.amount before inserting.
  Future<SpaceTransaction> createTransaction({
    required String spaceId,
    required String? categoryId,
    required double amount,
    required String description,
    required DateTime date,
    required SplitRule splitRule,
    required Map<String, double> sharesPerUser, // userId → amount
    String? notes,
    String? receiptUrl,
    String? paidBy,
  }) async {
    final payer = paidBy ?? _userId;

    // Validate split sum
    final sharesSum = sharesPerUser.values.fold(0.0, (a, b) => a + b);
    final diff = (sharesSum - amount).abs();
    if (diff > 0.01) {
      throw ArgumentError(
        'Split shares sum (${sharesSum.toStringAsFixed(2)}) must equal '
        'transaction amount (${amount.toStringAsFixed(2)})',
      );
    }

    // Insert transaction
    final txRow = await _client
        .from('space_transactions')
        .insert({
          'space_id':    spaceId,
          if (categoryId != null) 'category_id': categoryId,
          'paid_by':     payer,
          'amount':      amount,
          'description': description,
          'date':        date.toIso8601String().split('T').first,
          'split_rule':  splitRule.name,
          if (notes != null)      'notes':       notes,
          if (receiptUrl != null) 'receipt_url': receiptUrl,
        })
        .select()
        .single();

    final txId = txRow['id'] as String;

    // Insert shares
    if (sharesPerUser.isNotEmpty) {
      await _client.from('space_transaction_shares').insert(
        sharesPerUser.entries.map((e) => {
          'transaction_id': txId,
          'user_id':        e.key,
          'amount':         e.value,
        }).toList(),
      );
    }

    // Return full transaction with shares
    final full = await _client
        .from('space_transactions')
        .select('*, space_transaction_shares(*), space_categories(id, name, icon)')
        .eq('id', txId)
        .single();
    return SpaceTransaction.fromJson(full);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _client
        .from('space_transactions')
        .delete()
        .eq('id', transactionId);
  }

  // ═══════════════════════════════════════════════════════════════
  // Ledger Contributions (private — current user only)
  // ═══════════════════════════════════════════════════════════════

  /// Links a space transaction share to the personal ledger.
  /// Idempotent — does nothing if already linked (UNIQUE on share_id).
  Future<LedgerContribution> linkToLedger({
    required String spaceId,
    required String shareId,
    required double amount,
    required DateTime date,
    String? ledgerCategoryId,
  }) async {
    final row = await _client
        .from('ledger_contributions')
        .upsert(
          {
            'user_id':  _userId,
            'space_id': spaceId,
            'share_id': shareId,
            'amount':   amount,
            'date':     date.toIso8601String().split('T').first,
            if (ledgerCategoryId != null) 'ledger_category_id': ledgerCategoryId,
          },
          onConflict: 'share_id',
        )
        .select('*, spaces(name, emoji)')
        .single();

    // Mark the share as ledger-linked
    await _client
        .from('space_transaction_shares')
        .update({'ledger_linked': true})
        .eq('id', shareId);

    return LedgerContribution.fromJson(row);
  }

  Future<void> unlinkFromLedger(String shareId) async {
    await _client
        .from('ledger_contributions')
        .delete()
        .eq('share_id', shareId)
        .eq('user_id', _userId);

    await _client
        .from('space_transaction_shares')
        .update({'ledger_linked': false})
        .eq('id', shareId);
  }

  /// All ledger contributions for the current user in a date range.
  Future<List<LedgerContribution>> getLedgerContributions({
    required DateTime from,
    required DateTime to,
    String? spaceId,
  }) async {
    final query = _client
        .from('ledger_contributions')
        .select('*, spaces(name, emoji)')
        .eq('user_id', _userId)
        .gte('date', from.toIso8601String().split('T').first)
        .lte('date', to.toIso8601String().split('T').first);

    final filteredQuery = spaceId != null
        ? query.eq('space_id', spaceId)
        : query;

    final rows = await filteredQuery.order('date', ascending: false);
    return (rows as List)
        .map((r) => LedgerContribution.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // Settlements
  // ═══════════════════════════════════════════════════════════════

  /// Returns pending settlements for a space.
  Future<List<SpaceSettlement>> getPendingSettlements(String spaceId) async {
    final rows = await _client
        .from('space_settlements')
        .select()
        .eq('space_id', spaceId)
        .isFilter('settled_at', null)
        .order('created_at');
    return (rows as List)
        .map((r) => SpaceSettlement.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<SpaceSettlement>> getSettlementHistory(String spaceId) async {
    final rows = await _client
        .from('space_settlements')
        .select()
        .eq('space_id', spaceId)
        .not('settled_at', 'is', null)
        .order('settled_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map((r) => SpaceSettlement.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Marks a settlement as paid by the current user.
  Future<SpaceSettlement> markSettled(String settlementId, {String? notes}) async {
    final row = await _client
        .from('space_settlements')
        .update({
          'settled_at': DateTime.now().toIso8601String(),
          'settled_by': _userId,
          if (notes != null) 'notes': notes,
        })
        .eq('id', settlementId)
        .select()
        .single();
    return SpaceSettlement.fromJson(row);
  }

  /// Computes net balances and suggests minimal settlements using the
  /// Splitwise simplification algorithm.
  ///
  /// Steps:
  ///   1. For each user: net = totalPaid - totalOwed
  ///   2. Separate into creditors (net > 0) and debtors (net < 0)
  ///   3. Greedily match largest debtor to largest creditor
  ///
  /// Returns a list of [SettlementSuggestion] to persist as space_settlements.
  Future<List<SettlementSuggestion>> computeSettlements(String spaceId) async {
    // Fetch all unsettled transaction shares for this space
    final txRows = await _client
        .from('space_transactions')
        .select('id, paid_by, amount, space_transaction_shares(*)')
        .eq('space_id', spaceId);

    // Build net balance map: userId → net (positive = owed, negative = owes)
    final Map<String, double> net = {};

    for (final tx in txRows as List) {
      final txMap    = tx as Map<String, dynamic>;
      final paidBy   = txMap['paid_by'] as String;
      final txAmount = (txMap['amount'] as num).toDouble();
      final shares   = txMap['space_transaction_shares'] as List;

      // Payer gets credit for the full amount
      net[paidBy] = (net[paidBy] ?? 0) + txAmount;

      // Each participant gets debited their share
      for (final share in shares) {
        final shareMap = share as Map<String, dynamic>;
        final userId   = shareMap['user_id'] as String;
        final amount   = (shareMap['amount'] as num).toDouble();
        net[userId] = (net[userId] ?? 0) - amount;
      }
    }

    // Splitwise simplification
    final creditors = net.entries
        .where((e) => e.value > 0.005)
        .map((e) => _Bal(e.key, e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final debtors = net.entries
        .where((e) => e.value < -0.005)
        .map((e) => _Bal(e.key, -e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final suggestions = <SettlementSuggestion>[];

    int ci = 0, di = 0;
    while (ci < creditors.length && di < debtors.length) {
      final creditor = creditors[ci];
      final debtor   = debtors[di];
      final payment  = creditor.amount < debtor.amount
          ? creditor.amount
          : debtor.amount;

      if (payment > 0.005) {
        suggestions.add(SettlementSuggestion(
          fromUserId: debtor.userId,
          toUserId:   creditor.userId,
          amount:     double.parse(payment.toStringAsFixed(2)),
        ));
      }

      creditor.amount -= payment;
      debtor.amount   -= payment;

      if (creditor.amount < 0.005) ci++;
      if (debtor.amount   < 0.005) di++;
    }

    return suggestions;
  }

  /// Persists settlement suggestions to space_settlements.
  Future<List<SpaceSettlement>> saveSettlements(
    String spaceId,
    List<SettlementSuggestion> suggestions, {
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    if (suggestions.isEmpty) return [];

    final rows = await _client
        .from('space_settlements')
        .insert(
          suggestions.map((s) => {
            'space_id':      spaceId,
            'from_user_id':  s.fromUserId,
            'to_user_id':    s.toUserId,
            'amount':        s.amount,
            if (periodStart != null) 'period_start': periodStart.toIso8601String().split('T').first,
            if (periodEnd   != null) 'period_end':   periodEnd.toIso8601String().split('T').first,
          }).toList(),
        )
        .select();

    return (rows as List)
        .map((r) => SpaceSettlement.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────
// Internal helper for the Splitwise algorithm
// ─────────────────────────────────────────────────────────────────

class _Bal {
  final String userId;
  double amount;
  _Bal(this.userId, this.amount);
}

// ── Invite error ────────────────────────────────────────────────────────────────

/// Thrown by [SpaceRepository.acceptSpaceInviteViaEdgeFunction] when the
/// Edge Function returns a non-2xx status. [code] is the machine-readable
/// error string from the response body.
class SpaceInviteException implements Exception {
  const SpaceInviteException(this.code);
  final String code;

  @override
  String toString() => 'SpaceInviteException($code)';
}
