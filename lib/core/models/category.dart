
class Category {
  final int id;
  final String dbValue;
  final String name;
  final String emoji;
  final bool isSwile;
  final bool isSystem;
  final int orderIndex;

  const Category({
    this.id = -1,
    required this.dbValue,
    required this.name,
    required this.emoji,
    this.isSwile = false,
    this.isSystem = false,
    this.orderIndex = 0,
  });

  Category copyWith({
    int? id,
    String? dbValue,
    String? name,
    String? emoji,
    bool? isSwile,
    bool? isSystem,
    int? orderIndex,
  }) {
    return Category(
      id: id ?? this.id,
      dbValue: dbValue ?? this.dbValue,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      isSwile: isSwile ?? this.isSwile,
      isSystem: isSystem ?? this.isSystem,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      dbValue: json['db_value'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      isSwile: json['is_swile'] as bool? ?? false,
      isSystem: json['is_system'] as bool? ?? false,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'db_value': dbValue,
      'name': name,
      'emoji': emoji,
      'is_swile': isSwile,
      'is_system': isSystem,
      'order_index': orderIndex,
    };
  }
}
