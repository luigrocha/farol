import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/models/workspace.dart';
import '../../core/providers/workspace_providers.dart';

/// Bottom sheet to invite a member to a workspace by email.
/// Only shown to owner/admin.
class InviteMemberSheet extends ConsumerStatefulWidget {
  const InviteMemberSheet({super.key, required this.workspace});

  final Workspace workspace;

  static Future<void> show(BuildContext context, Workspace workspace) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => InviteMemberSheet(workspace: workspace),
      );

  @override
  ConsumerState<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<InviteMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  WorkspaceRole _selectedRole = WorkspaceRole.member;
  bool _loading = false;
  WorkspaceInvite? _createdInvite;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final repo = ref.read(workspaceRepositoryProvider);
      final invite = await repo.createInvite(
        workspaceId: widget.workspace.id,
        email: _emailController.text.trim(),
        role: _selectedRole,
      );
      setState(() => _createdInvite = invite);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending invite: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: _createdInvite != null
          ? _InviteSuccessView(
              invite: _createdInvite!,
              workspaceName: widget.workspace.name,
              onDone: () => Navigator.pop(context),
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle ────────────────────────────────────
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Invite member',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.workspace.name,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ── Email field ───────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // ── Role picker ───────────────────────────────
                  Text(
                    'Role',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RolePicker(
                    value: _selectedRole,
                    onChanged: (r) => setState(() => _selectedRole = r),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text('Send invite'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Role selector — segmented button with description below.
class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.value, required this.onChanged});

  final WorkspaceRole value;
  final ValueChanged<WorkspaceRole> onChanged;

  static const _roles = [
    WorkspaceRole.admin,
    WorkspaceRole.member,
    WorkspaceRole.viewer,
  ];

  static String _label(WorkspaceRole r) => switch (r) {
        WorkspaceRole.admin  => 'Admin',
        WorkspaceRole.member => 'Member',
        WorkspaceRole.viewer => 'Viewer',
        _                    => r.name,
      };

  static String _description(WorkspaceRole r) => switch (r) {
        WorkspaceRole.admin  => 'Can add, edit, delete, and invite others',
        WorkspaceRole.member => 'Can add and edit data',
        WorkspaceRole.viewer => 'Read-only access',
        _                    => '',
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<WorkspaceRole>(
          segments: _roles
              .map((r) => ButtonSegment(value: r, label: Text(_label(r))))
              .toList(),
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
        const SizedBox(height: 6),
        Text(
          _description(value),
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Shown after the invite is created — displays the token link with share options.
class _InviteSuccessView extends StatelessWidget {
  const _InviteSuccessView({
    required this.invite,
    required this.workspaceName,
    required this.onDone,
  });

  final WorkspaceInvite invite;
  final String workspaceName;
  final VoidCallback onDone;

  String get _inviteLink =>
      '${AppConfig.baseUrl}/#/invite/${invite.token}';

  Future<void> _shareNative(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await Share.share(
      l10n.inviteShareText(workspaceName, _inviteLink),
      subject: l10n.inviteShareEmailSubject(workspaceName),
    );
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final text = Uri.encodeComponent(
        l10n.inviteShareText(workspaceName, _inviteLink));
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp not available')),
      );
    }
  }

  Future<void> _shareEmail(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final subject = Uri.encodeComponent(
        l10n.inviteShareEmailSubject(workspaceName));
    final body = Uri.encodeComponent(
        l10n.inviteShareText(workspaceName, _inviteLink));
    final uri = Uri.parse('mailto:${invite.invitedEmail}?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      await _shareNative(context);
    }
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _inviteLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Handle ────────────────────────────────────────────────────────
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // ── Check icon + title ────────────────────────────────────────────
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.green, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          'Invite created!',
          style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Share with ${invite.invitedEmail}',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // ── Link card ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _inviteLink,
                  style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy link',
                visualDensity: VisualDensity.compact,
                onPressed: () => _copyLink(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Expires in 7 days',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),

        // ── Share buttons ─────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _ShareButton(
                icon: Icons.email_outlined,
                label: 'Email',
                onTap: () => _shareEmail(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareButton(
                icon: Icons.chat_outlined,
                label: 'WhatsApp',
                onTap: () => _shareWhatsApp(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareButton(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: () => _shareNative(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Done ──────────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onDone,
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
