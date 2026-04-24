import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/net_worth_snapshot.dart';

class NetWorthRepository {
  final SupabaseClient _supabase;
  const NetWorthRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<NetWorthSnapshot?> getByMonth(int month, int year) async {
    final userId = _userId;
    if (userId == null) return null;
    final data = await _supabase
        .from('net_worth_snapshots')
        .select()
        .eq('user_id', userId)
        .eq('month', month)
        .eq('year', year)
        .maybeSingle();
    if (data == null) return null;
    return NetWorthSnapshot.fromJson(data);
  }

  Future<void> upsert({
    required int month,
    required int year,
    double patrimonyTotal = 0,
    double fgtsBalance = 0,
    double investmentsTotal = 0,
    double emergencyFund = 0,
    double pendingInstallments = 0,
    String? notes,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.from('net_worth_snapshots').upsert({
      'user_id': userId,
      'month': month,
      'year': year,
      'patrimony_total': patrimonyTotal,
      'fgts_balance': fgtsBalance,
      'investments_total': investmentsTotal,
      'emergency_fund': emergencyFund,
      'pending_installments': pendingInstallments,
      if (notes != null) 'notes': notes,
    }, onConflict: 'user_id,month,year');
  }
}
