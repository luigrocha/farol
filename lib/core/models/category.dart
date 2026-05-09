
class Category {
  final String id;
  final String? userId;
  final String? workspaceId;
  final String? parentId;
  final String slug;
  final String name;
  final String emoji;
  final String? colorHex;
  final String financialType; // 'need' | 'want' | 'investment' | 'income' | 'transfer'
  final bool isSystem;
  final bool isSwile;
  final bool isFixed;
  final bool isArchived;
  final int displayOrder;

  const Category({
    this.id = '',
    this.userId,
    this.workspaceId,
    this.parentId,
    required this.slug,
    required this.name,
    required this.emoji,
    this.colorHex,
    this.financialType = 'want',
    this.isSystem = false,
    this.isSwile = false,
    this.isFixed = false,
    this.isArchived = false,
    this.displayOrder = 0,
  });

  // Legacy adapter — maps old UPPERCASE dbValue to slug
  static String slugFromLegacy(String dbValue) => dbValue.toLowerCase();

  Category copyWith({
    String? id,
    String? userId,
    String? workspaceId,
    String? parentId,
    String? slug,
    String? name,
    String? emoji,
    String? colorHex,
    String? financialType,
    bool? isSystem,
    bool? isSwile,
    bool? isFixed,
    bool? isArchived,
    int? displayOrder,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workspaceId: workspaceId ?? this.workspaceId,
      parentId: parentId ?? this.parentId,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      financialType: financialType ?? this.financialType,
      isSystem: isSystem ?? this.isSystem,
      isSwile: isSwile ?? this.isSwile,
      isFixed: isFixed ?? this.isFixed,
      isArchived: isArchived ?? this.isArchived,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      workspaceId: json['workspace_id'] as String?,
      parentId: json['parent_id'] as String?,
      slug: json['slug'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      colorHex: json['color_hex'] as String?,
      financialType: json['financial_type'] as String? ?? 'want',
      isSystem: json['is_system'] as bool? ?? false,
      isSwile: json['is_swile'] as bool? ?? false,
      isFixed: json['is_fixed'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'parent_id': parentId,
      'slug': slug,
      'name': name,
      'emoji': emoji,
      'color_hex': colorHex,
      'financial_type': financialType,
      'is_system': isSystem,
      'is_swile': isSwile,
      'is_fixed': isFixed,
      'is_archived': isArchived,
      'display_order': displayOrder,
    };
  }
}
