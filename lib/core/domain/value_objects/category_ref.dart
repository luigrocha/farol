import '../../models/category.dart';

/// Immutable reference to a category. Never throws — unknown categories
/// resolve to [CategoryRef.uncategorized].
class CategoryRef {
  final String id;
  final String slug;
  final String name;
  final String emoji;
  final String? colorHex;
  final String financialType;
  final String? parentId;
  final bool isSystem;
  final bool isSwile;
  final bool isFixed;

  const CategoryRef({
    required this.id,
    required this.slug,
    required this.name,
    required this.emoji,
    this.colorHex,
    this.financialType = 'want',
    this.parentId,
    this.isSystem = false,
    this.isSwile = false,
    this.isFixed = false,
  });

  bool get isCustom => !isSystem;

  factory CategoryRef.fromCategory(Category c) => CategoryRef(
        id: c.id,
        slug: c.slug,
        name: c.name,
        emoji: c.emoji,
        colorHex: c.colorHex,
        financialType: c.financialType,
        parentId: c.parentId,
        isSystem: c.isSystem,
        isSwile: c.isSwile,
        isFixed: c.isFixed,
      );

  /// Safe fallback — never throws, never returns null.
  static CategoryRef uncategorized(String rawValue) => CategoryRef(
        id: '',
        slug: rawValue.toLowerCase(),
        name: rawValue,
        emoji: '📋',
        financialType: 'want',
      );

  /// Resolves a raw string (UPPERCASE legacy or lowercase slug) to a CategoryRef.
  /// Returns [uncategorized] if not found — never throws StateError.
  static CategoryRef fromLegacyString(String rawValue, List<CategoryRef> all) {
    final normalized = rawValue.toLowerCase();
    return all.firstWhere(
      (c) => c.slug == normalized,
      orElse: () => CategoryRef.uncategorized(rawValue),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CategoryRef && other.slug == slug && other.id == id;

  @override
  int get hashCode => Object.hash(id, slug);
}
