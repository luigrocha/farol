import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryRepository {
  final SupabaseClient _supabase;
  const CategoryRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<Category>> watchAll() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);
    return _supabase
        .from('categories')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('order_index', ascending: true)
        .map((rows) => rows.map(Category.fromJson).toList());
  }

  Future<List<Category>> getAll() async {
    final userId = _userId;
    if (userId == null) return [];
    final data = await _supabase
        .from('categories')
        .select()
        .eq('user_id', userId)
        .order('order_index', ascending: true);
    return data.map((r) => Category.fromJson(r)).toList();
  }

  Future<Category> insert(Category category) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');
    
    final data = await _supabase.from('categories').insert({
      'user_id': userId,
      'db_value': category.dbValue,
      'name': category.name,
      'emoji': category.emoji,
      'is_swile': category.isSwile,
      'is_system': category.isSystem,
      'order_index': category.orderIndex,
    }).select().single();
    
    return Category.fromJson(data);
  }

  Future<void> update(Category category) async {
    await _supabase.from('categories').update({
      'db_value': category.dbValue,
      'name': category.name,
      'emoji': category.emoji,
      'is_swile': category.isSwile,
      'is_system': category.isSystem,
      'order_index': category.orderIndex,
    }).eq('id', category.id);
  }

  Future<void> delete(int id) async {
    await _supabase.from('categories').delete().eq('id', id);
  }

  Future<void> insertAll(List<Map<String, dynamic>> rows) async {
    final userId = _userId;
    if (userId == null) return;
    final rowsWithUser = rows.map((r) => {...r, 'user_id': userId}).toList();
    await _supabase.from('categories').insert(rowsWithUser);
  }

  Future<void> reorder(List<Category> categories) async {
    final userId = _userId;
    if (userId == null) return;

    final updates = categories.asMap().entries.map((entry) {
      return {
        'id': entry.value.id,
        'user_id': userId,
        'order_index': entry.key,
      };
    }).toList();

    await _supabase.from('categories').upsert(updates);
  }

  Future<void> seedInitialCategories() async {
    final userId = _userId;
    if (userId == null) return;

    final existing = await getAll();
    if (existing.isNotEmpty) return;

    final initialCategories = [
      {'db_value': 'HOUSING', 'name': 'Housing', 'emoji': '🏠', 'is_system': true, 'order_index': 0},
      {'db_value': 'TRANSPORT', 'name': 'Transport', 'emoji': '🚗', 'is_system': true, 'order_index': 1},
      {'db_value': 'FOOD_GROCERY', 'name': 'Food/Grocery', 'emoji': '🛒', 'is_swile': true, 'is_system': true, 'order_index': 2},
      {'db_value': 'HEALTH', 'name': 'Health', 'emoji': '🏥', 'is_system': true, 'order_index': 3},
      {'db_value': 'SUBSCRIPTIONS', 'name': 'Subscriptions', 'emoji': '📱', 'is_system': true, 'order_index': 4},
      {'db_value': 'LEISURE', 'name': 'Leisure', 'emoji': '🎮', 'is_system': true, 'order_index': 5},
      {'db_value': 'EDUCATION', 'name': 'Education', 'emoji': '📚', 'is_system': true, 'order_index': 6},
      {'db_value': 'CARD_INSTALLMENTS', 'name': 'Card Installments', 'emoji': '💳', 'is_system': true, 'order_index': 7},
      {'db_value': 'OTHER', 'name': 'Other', 'emoji': '📋', 'is_system': true, 'order_index': 8},
    ];

    await insertAll(initialCategories);
  }
}
