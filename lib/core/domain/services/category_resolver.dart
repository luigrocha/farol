import '../value_objects/category_ref.dart';

/// Resolves raw category strings (legacy UPPERCASE or new slug) to [CategoryRef].
/// Backed by an in-memory cache of loaded categories.
/// Never throws — unknown values resolve to [CategoryRef.uncategorized].
class CategoryResolver {
  List<CategoryRef> _cache = [];

  void updateCache(List<CategoryRef> categories) {
    _cache = categories;
  }

  CategoryRef resolve(String rawValue) =>
      CategoryRef.fromLegacyString(rawValue, _cache);

  bool get isLoaded => _cache.isNotEmpty;
}
