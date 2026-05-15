// lib/core/models/space.dart
// Spaces v2 — bounded shared financial contexts.
// See docs/architecture/workspace_architecture_v2.md

import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────

enum SpaceType { household, trip, project, family, business }

extension SpaceTypeX on SpaceType {
  String get label => switch (this) {
        SpaceType.household => 'Casa',
        SpaceType.trip      => 'Viagem',
        SpaceType.project   => 'Projeto',
        SpaceType.family    => 'Família',
        SpaceType.business  => 'Negócio',
      };

  String get defaultEmoji => switch (this) {
        SpaceType.household => '🏠',
        SpaceType.trip      => '✈️',
        SpaceType.project   => '💼',
        SpaceType.family    => '👨‍👩‍👧',
        SpaceType.business  => '🏢',
      };

  static SpaceType parse(String? value) => switch (value) {
        'trip'      => SpaceType.trip,
        'project'   => SpaceType.project,
        'family'    => SpaceType.family,
        'business'  => SpaceType.business,
        _           => SpaceType.household,
      };
}

// ─────────────────────────────────────────────────────────────────

enum SpaceRole { owner, admin, member, viewer, guest }

extension SpaceRoleX on SpaceRole {
  bool get canWrite => this == SpaceRole.owner ||
      this == SpaceRole.admin ||
      this == SpaceRole.member;

  bool get isAdmin => this == SpaceRole.owner || this == SpaceRole.admin;
  bool get isOwner => this == SpaceRole.owner;

  static SpaceRole parse(String? value) => switch (value) {
        'owner'  => SpaceRole.owner,
        'admin'  => SpaceRole.admin,
        'member' => SpaceRole.member,
        'guest'  => SpaceRole.guest,
        _        => SpaceRole.viewer,
      };
}

// ─────────────────────────────────────────────────────────────────

enum SplitRule { equal, custom, percentage, solo }

extension SplitRuleX on SplitRule {
  String get label => switch (this) {
        SplitRule.equal      => 'Igualmente',
        SplitRule.custom     => 'Personalizado',
        SplitRule.percentage => 'Percentual',
        SplitRule.solo       => 'Apenas eu',
      };

  static SplitRule parse(String? value) => switch (value) {
        'custom'     => SplitRule.custom,
        'percentage' => SplitRule.percentage,
        'solo'       => SplitRule.solo,
        _            => SplitRule.equal,
      };
}

// ─────────────────────────────────────────────────────────────────
// SpaceMember
// ─────────────────────────────────────────────────────────────────

@immutable
class SpaceMember {
  final String id;
  final String spaceId;
  final String userId;
  final SpaceRole role;

  // Capability overrides — null means "use role default"
  final bool? canAddExpenses;
  final bool? canSeeBalances;
  final bool? canSeeMemberBalances;
  final bool? canExport;
  final bool? canSeeSettlements;

  final String? invitedBy;
  final DateTime joinedAt;

  const SpaceMember({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.role,
    this.canAddExpenses,
    this.canSeeBalances,
    this.canSeeMemberBalances,
    this.canExport,
    this.canSeeSettlements,
    this.invitedBy,
    required this.joinedAt,
  });

  // Resolved capability — override takes precedence over role default
  bool get effectiveCanAddExpenses =>
      canAddExpenses ?? role.canWrite;

  bool get effectiveCanSeeBalances =>
      canSeeBalances ?? true; // visible to all roles by default

  bool get effectiveCanSeeMemberBalances =>
      canSeeMemberBalances ?? (role != SpaceRole.viewer && role != SpaceRole.guest);

  bool get effectiveCanExport =>
      canExport ?? role.isAdmin;

  bool get effectiveCanSeeSettlements =>
      canSeeSettlements ?? (role != SpaceRole.viewer && role != SpaceRole.guest);

  factory SpaceMember.fromJson(Map<String, dynamic> json) => SpaceMember(
        id:                    json['id'] as String,
        spaceId:               json['space_id'] as String,
        userId:                json['user_id'] as String,
        role:                  SpaceRoleX.parse(json['role'] as String?),
        canAddExpenses:        json['can_add_expenses'] as bool?,
        canSeeBalances:        json['can_see_balances'] as bool?,
        canSeeMemberBalances:  json['can_see_member_balances'] as bool?,
        canExport:             json['can_export'] as bool?,
        canSeeSettlements:     json['can_see_settlements'] as bool?,
        invitedBy:             json['invited_by'] as String?,
        joinedAt:              DateTime.parse(json['joined_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id':                     id,
        'space_id':               spaceId,
        'user_id':                userId,
        'role':                   role.name,
        if (canAddExpenses != null) 'can_add_expenses': canAddExpenses,
        if (canSeeBalances != null) 'can_see_balances': canSeeBalances,
        if (canSeeMemberBalances != null) 'can_see_member_balances': canSeeMemberBalances,
        if (canExport != null) 'can_export': canExport,
        if (canSeeSettlements != null) 'can_see_settlements': canSeeSettlements,
        if (invitedBy != null) 'invited_by': invitedBy,
        'joined_at': joinedAt.toIso8601String(),
      };

  SpaceMember copyWith({SpaceRole? role, bool? canAddExpenses}) => SpaceMember(
        id:                   id,
        spaceId:              spaceId,
        userId:               userId,
        role:                 role ?? this.role,
        canAddExpenses:       canAddExpenses ?? this.canAddExpenses,
        canSeeBalances:       canSeeBalances,
        canSeeMemberBalances: canSeeMemberBalances,
        canExport:            canExport,
        canSeeSettlements:    canSeeSettlements,
        invitedBy:            invitedBy,
        joinedAt:             joinedAt,
      );
}

// ─────────────────────────────────────────────────────────────────
// Space
// ─────────────────────────────────────────────────────────────────

@immutable
class Space {
  final String id;
  final String name;
  final String? emoji;
  final String? color;
  final String? description;
  final SpaceType type;
  final String ownerId;
  final String currency;
  final Map<String, dynamic> settings;
  final List<SpaceMember> members;

  // Trip/project lifecycle
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? archivedAt;

  // Migration ref — null for spaces created natively in v2
  final String? legacyWorkspaceId;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Space({
    required this.id,
    required this.name,
    this.emoji,
    this.color,
    this.description,
    this.type = SpaceType.household,
    required this.ownerId,
    this.currency = 'BRL',
    this.settings = const {},
    this.members = const [],
    this.startsAt,
    this.endsAt,
    this.archivedAt,
    this.legacyWorkspaceId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isArchived => archivedAt != null;
  bool get isActive   => archivedAt == null;
  bool get isTimeBounded => startsAt != null || endsAt != null;

  /// Role of [userId] in this space. Defaults to viewer if not a member.
  SpaceRole roleFor(String userId) =>
      members
          .where((m) => m.userId == userId)
          .map((m) => m.role)
          .firstOrNull ??
      SpaceRole.viewer;

  /// Effective write capability for [userId], considering capability overrides.
  bool canWriteFor(String userId) {
    final member = members.where((m) => m.userId == userId).firstOrNull;
    if (member == null) return false;
    return member.effectiveCanAddExpenses;
  }

  factory Space.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['space_members'] as List<dynamic>? ?? [];
    return Space(
      id:                 json['id'] as String,
      name:               json['name'] as String,
      emoji:              json['emoji'] as String?,
      color:              json['color'] as String?,
      description:        json['description'] as String?,
      type:               SpaceTypeX.parse(json['type'] as String?),
      ownerId:            json['owner_id'] as String,
      currency:           (json['currency'] as String?) ?? 'BRL',
      settings:           (json['settings'] as Map<String, dynamic>?) ?? {},
      members:            membersRaw
                            .map((m) => SpaceMember.fromJson(m as Map<String, dynamic>))
                            .toList(),
      startsAt:           json['starts_at'] != null
                            ? DateTime.parse(json['starts_at'] as String)
                            : null,
      endsAt:             json['ends_at'] != null
                            ? DateTime.parse(json['ends_at'] as String)
                            : null,
      archivedAt:         json['archived_at'] != null
                            ? DateTime.parse(json['archived_at'] as String)
                            : null,
      legacyWorkspaceId:  json['legacy_workspace_id'] as String?,
      createdAt:          DateTime.parse(json['created_at'] as String),
      updatedAt:          DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id':          id,
        'name':        name,
        if (emoji != null)       'emoji': emoji,
        if (color != null)       'color': color,
        if (description != null) 'description': description,
        'type':        type.name,
        'owner_id':    ownerId,
        'currency':    currency,
        'settings':    settings,
        if (startsAt != null) 'starts_at': startsAt!.toIso8601String(),
        if (endsAt != null)   'ends_at':   endsAt!.toIso8601String(),
      };

  Space copyWith({
    String? name,
    String? emoji,
    String? color,
    String? description,
    SpaceType? type,
    List<SpaceMember>? members,
    DateTime? startsAt,
    DateTime? endsAt,
    DateTime? archivedAt,
  }) =>
      Space(
        id:                id,
        name:              name ?? this.name,
        emoji:             emoji ?? this.emoji,
        color:             color ?? this.color,
        description:       description ?? this.description,
        type:              type ?? this.type,
        ownerId:           ownerId,
        currency:          currency,
        settings:          settings,
        members:           members ?? this.members,
        startsAt:          startsAt ?? this.startsAt,
        endsAt:            endsAt ?? this.endsAt,
        archivedAt:        archivedAt ?? this.archivedAt,
        legacyWorkspaceId: legacyWorkspaceId,
        createdAt:         createdAt,
        updatedAt:         updatedAt,
      );
}
