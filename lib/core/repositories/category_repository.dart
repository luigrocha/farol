import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryRepository {
  final SupabaseClient _supabase;
  final String? workspaceId;

  const CategoryRepository(this._supabase, {this.workspaceId});

  String? get _userId => _supabase.auth.currentUser?.id;

  // Returns system categories (user_id IS NULL) + user's custom categories.
  // System categories always have user_id IS NULL — their workspace_id was
  // assigned by V29 to whichever workspace existed at migration time, NOT to
  // each user's workspace. So we must NOT filter by workspace_id for system
  // rows; instead we keep any row where user_id IS NULL (system) OR the row
  // belongs to the active workspace (custom).
  Stream<List<Category>> watchAll() {
    final wsId = workspaceId;
    final userId = _userId;
    if (wsId != null) {
      return _supabase
          .from('categories')
          .stream(primaryKey: ['id'])
          .order('display_order', ascending: true)
          .map((rows) => rows
              .map(Category.fromJson)
              .where((c) =>
                  c.userId == null ||          // system category — always visible
                  c.workspaceId == wsId)       // or belongs to active workspace
              .where((c) => !c.isArchived)
              .toList());
    }
    if (userId == null) return Stream.value([]);
    return _supabase
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('display_order', ascending: true)
        .map((rows) => rows
            .map(Category.fromJson)
            .where((c) => c.userId == null || c.userId == userId)
            .where((c) => !c.isArchived)
            .toList());
  }

  Future<List<Category>> getAll() async {
    final wsId = workspaceId;
    final userId = _userId;
    if (wsId != null) {
      // System rows have user_id IS NULL (not workspace_id IS NULL — V29 assigned
      // a workspace_id to them). Use user_id IS NULL to identify system categories.
      final data = await _supabase
          .from('categories')
          .select()
          .or('user_id.is.null,workspace_id.eq.$wsId')
          .eq('is_archived', false)
          .order('display_order', ascending: true);
      return data.map((r) => Category.fromJson(r)).toList();
    }
    if (userId == null) return [];
    final data = await _supabase
        .from('categories')
        .select()
        .or('user_id.is.null,user_id.eq.$userId')
        .eq('is_archived', false)
        .order('display_order', ascending: true);
    return data.map((r) => Category.fromJson(r)).toList();
  }

  Future<Category> insert(Category category) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final data = await _supabase.from('categories').insert({
      'user_id': userId,
      if (workspaceId != null) 'workspace_id': workspaceId,
      'slug': category.slug,
      'name': category.name,
      'emoji': category.emoji,
      'color_hex': category.colorHex,
      'financial_type': category.financialType,
      'is_swile': category.isSwile,
      'is_system': false,
      'is_fixed': category.isFixed,
      'display_order': category.displayOrder,
    }).select().single();

    return Category.fromJson(data);
  }

  Future<void> update(Category category) async {
    await _supabase.from('categories').update({
      'slug': category.slug,
      'name': category.name,
      'emoji': category.emoji,
      'color_hex': category.colorHex,
      'financial_type': category.financialType,
      'is_swile': category.isSwile,
      'is_fixed': category.isFixed,
      'display_order': category.displayOrder,
    }).eq('id', category.id);
  }

  Future<void> archive(String id) async {
    await _supabase.from('categories').update({'is_archived': true}).eq('id', id);
  }

  Future<void> reorder(List<Category> categories) async {
    final updates = categories.asMap().entries.map((entry) {
      return {'id': entry.value.id, 'display_order': entry.key};
    }).toList();
    await _supabase.from('categories').upsert(updates);
  }
}
