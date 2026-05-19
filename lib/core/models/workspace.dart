import 'package:flutter/foundation.dart';

enum WorkspacePlan { free, premium }

enum WorkspaceRole { owner, admin, member, viewer }

enum WorkspaceType { personal, shared }

extension WorkspaceTypeX on WorkspaceType {
  bool get isShared => this == WorkspaceType.shared;
  bool get isPersonal => this == WorkspaceType.personal;

  static WorkspaceType parse(String? value) => switch (value) {
        'shared' => WorkspaceType.shared,
        _ => WorkspaceType.personal,
      };
}

// ─────────────────────────────────────────────────────────────
// WorkspaceMember
// ─────────────────────────────────────────────────────────────

class WorkspaceMember {
  final String id;
  final String workspaceId;
  final String userId;
  final WorkspaceRole role;
  final String? invitedBy;
  final DateTime joinedAt;

  const WorkspaceMember({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.role,
    this.invitedBy,
    required this.joinedAt,
  });

  static WorkspaceRole _parseRole(String? r) => switch (r) {
        'owner' => WorkspaceRole.owner,
        'admin' => WorkspaceRole.admin,
        'member' => WorkspaceRole.member,
        _ => WorkspaceRole.viewer,
      };

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) {
    return WorkspaceMember(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      userId: json['user_id'] as String,
      role: _parseRole(json['role'] as String?),
      invitedBy: json['invited_by'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'workspace_id': workspaceId,
        'user_id': userId,
        'role': role.name,
        if (invitedBy != null) 'invited_by': invitedBy,
        'joined_at': joinedAt.toIso8601String(),
      };

  WorkspaceMember copyWith({WorkspaceRole? role}) => WorkspaceMember(
        id: id,
        workspaceId: workspaceId,
        userId: userId,
        role: role ?? this.role,
        invitedBy: invitedBy,
        joinedAt: joinedAt,
      );
}

// ─────────────────────────────────────────────────────────────
// WorkspaceInvite
// ─────────────────────────────────────────────────────────────

class WorkspaceInvite {
  final String id;
  final String workspaceId;
  final String invitedEmail;
  final WorkspaceRole role;
  final String token;
  final String invitedBy;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime createdAt;

  const WorkspaceInvite({
    required this.id,
    required this.workspaceId,
    required this.invitedEmail,
    required this.role,
    required this.token,
    required this.invitedBy,
    required this.expiresAt,
    this.acceptedAt,
    this.declinedAt,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isAccepted => acceptedAt != null;
  bool get isDeclined => declinedAt != null;
  bool get isPending => !isExpired && !isAccepted && !isDeclined;

  factory WorkspaceInvite.fromJson(Map<String, dynamic> json) {
    return WorkspaceInvite(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      invitedEmail: json['invited_email'] as String,
      role: WorkspaceMember._parseRole(json['role'] as String?),
      token: json['token'] as String,
      invitedBy: json['invited_by'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      declinedAt: json['declined_at'] != null
          ? DateTime.parse(json['declined_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Workspace
// ─────────────────────────────────────────────────────────────

@immutable
class Workspace {
  final String id;
  final String name;
  final String? slug;
  final String ownerId;
  final WorkspacePlan plan;
  final DateTime? planExpiresAt;
  final Map<String, dynamic> settings;
  final List<WorkspaceMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Phase 1: collaborative workspace identity
  final WorkspaceType type;
  final String? emoji;
  final String? color;
  final String? description;

  const Workspace({
    required this.id,
    required this.name,
    this.slug,
    required this.ownerId,
    this.plan = WorkspacePlan.free,
    this.planExpiresAt,
    this.settings = const {},
    this.members = const [],
    required this.createdAt,
    required this.updatedAt,
    this.type = WorkspaceType.personal,
    this.emoji,
    this.color,
    this.description,
  });

  bool get isPremium =>
      plan == WorkspacePlan.premium &&
      (planExpiresAt == null || planExpiresAt!.isAfter(DateTime.now()));

  factory Workspace.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['workspace_members'] as List<dynamic>? ?? [];
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      ownerId: json['owner_id'] as String,
      plan: (json['plan'] as String?) == 'premium'
          ? WorkspacePlan.premium
          : WorkspacePlan.free,
      planExpiresAt: json['plan_expires_at'] != null
          ? DateTime.parse(json['plan_expires_at'] as String)
          : null,
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      members: membersRaw
          .map((m) => WorkspaceMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      type: WorkspaceTypeX.parse(json['workspace_type'] as String?),
      emoji: json['emoji'] as String?,
      color: json['color'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (slug != null) 'slug': slug,
        'owner_id': ownerId,
        'plan': plan.name,
        if (planExpiresAt != null)
          'plan_expires_at': planExpiresAt!.toIso8601String(),
        'settings': settings,
        'workspace_type': type.name,
        if (emoji != null) 'emoji': emoji,
        if (color != null) 'color': color,
        if (description != null) 'description': description,
      };

  Workspace copyWith({
    String? name,
    WorkspacePlan? plan,
    DateTime? planExpiresAt,
    Map<String, dynamic>? settings,
    List<WorkspaceMember>? members,
    WorkspaceType? type,
    String? emoji,
    String? color,
    String? description,
  }) =>
      Workspace(
        id: id,
        name: name ?? this.name,
        slug: slug,
        ownerId: ownerId,
        plan: plan ?? this.plan,
        planExpiresAt: planExpiresAt ?? this.planExpiresAt,
        settings: settings ?? this.settings,
        members: members ?? this.members,
        createdAt: createdAt,
        updatedAt: updatedAt,
        type: type ?? this.type,
        emoji: emoji ?? this.emoji,
        color: color ?? this.color,
        description: description ?? this.description,
      );

  /// Role do usuário neste workspace. Retorna viewer se não for membro.
  WorkspaceRole roleFor(String userId) =>
      members.where((m) => m.userId == userId).map((m) => m.role).firstOrNull ??
      WorkspaceRole.viewer;

  /// Build a minimal Workspace from the accept-workspace-invite Edge Function
  /// response. Full member list will be loaded on the next getUserWorkspaces() call.
  factory Workspace.fromEdgeFunctionResponse(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      createdAt: now,
      updatedAt: now,
      type: WorkspaceTypeX.parse(json['workspace_type'] as String?),
      emoji: json['emoji'] as String?,
      color: json['color'] as String?,
    );
  }
}
