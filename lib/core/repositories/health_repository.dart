import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_snapshot.dart';

class HealthRepository {
  final SupabaseClient _supabase;
  const HealthRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> upsert({
    required int month,
    required int year,
    required int score,
    required double savingsRate,
    required double housingRate,
    required double monthlyBalance,
    required double emergencyFundMonths,
    required double installmentsRate,
    required double netSalary,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    await _supabase.from('health_snapshots').upsert({
      'user_id': userId,
      'month': month,
      'year': year,
      'score': score,
      'savings_rate': savingsRate,
      'housing_rate': housingRate,
      'monthly_balance': monthlyBalance,
      'emergency_fund_months': emergencyFundMonths,
      'installments_rate': installmentsRate,
      'net_salary': netSalary,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,month,year');
  }

  Future<List<HealthSnapshot>> fetchHistory() async {
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase
        .from('health_snapshots')
        .select()
        .eq('user_id', userId)
        .order('year', ascending: false)
        .order('month', ascending: false);
    return data.map((e) => HealthSnapshot.fromJson(e)).toList();
  }
}
