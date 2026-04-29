import 'enums.dart';

class Account {
  final int id;
  final String userId;
  final String name;
  final String institution;
  final String type;
  final double currentBalance;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.institution,
    required this.type,
    required this.currentBalance,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  AccountType get accountType => AccountType.fromDb(type);

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: (json['id'] as num).toInt(),
        userId: json['user_id'] as String,
        name: json['name'] as String,
        institution: json['institution'] as String,
        type: json['type'] as String,
        currentBalance: (json['current_balance'] as num).toDouble(),
        isActive: json['is_active'] as bool? ?? true,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Account copyWith({
    double? currentBalance,
    bool? isActive,
    String? name,
    String? institution,
    String? notes,
  }) =>
      Account(
        id: id,
        userId: userId,
        name: name ?? this.name,
        institution: institution ?? this.institution,
        type: type,
        currentBalance: currentBalance ?? this.currentBalance,
        isActive: isActive ?? this.isActive,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
