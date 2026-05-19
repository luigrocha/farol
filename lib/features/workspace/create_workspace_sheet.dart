import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/models/workspace.dart';
import '../../core/providers/workspace_providers.dart';

// ─────────────────────────────────────────────────────────────
// Emoji and color palettes
// ─────────────────────────────────────────────────────────────

const _kPersonalEmojis = ['🏠', '💼', '🎯', '🌱', '⭐', '🦋'];
const _kSharedEmojis = ['👥', '💑', '👨‍👩‍👧', '🏡', '🤝', '🚀'];
const _kAccentColors = [
  Color(0xFF00695C), // teal
  Color(0xFF1565C0), // blue
  Color(0xFF6A1B9A), // purple
  Color(0xFFE65100), // orange
  Color(0xFF2E7D32), // green
  Color(0xFFC62828), // red
];

// ─────────────────────────────────────────────────────────────
// CreateWorkspaceSheet
// ─────────────────────────────────────────────────────────────

/// Bottom sheet for creating a new workspace.
/// Phase 1: adds type picker (personal vs shared), emoji picker, color picker.
class CreateWorkspaceSheet extends ConsumerStatefulWidget {
  const CreateWorkspaceSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const CreateWorkspaceSheet(),
      );

  @override
  ConsumerState<CreateWorkspaceSheet> createState() =>
      _CreateWorkspaceSheetState();
}

class _CreateWorkspaceSheetState extends ConsumerState<CreateWorkspaceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _loading = false;

  WorkspaceType _type = WorkspaceType.shared;
  String? _selectedEmoji;
  Color? _selectedColor;

  List<String> get _emojis =>
      _type == WorkspaceType.shared ? _kSharedEmojis : _kPersonalEmojis;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = _kSharedEmojis.first;
    _selectedColor = _kAccentColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onTypeChanged(WorkspaceType type) {
    setState(() {
      _type = type;
      // Reset emoji to first in new type's list
      _selectedEmoji = _emojis.first;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final repo = ref.read(workspaceRepositoryProvider);
      final ws = await repo.create(
        name: _nameController.text.trim(),
        type: _type,
        emoji: _selectedEmoji,
        color: _selectedColor != null
            ? '#${_selectedColor!.toARGB32().toRadixString(16).substring(2).toUpperCase()}'
            : null,
      );
      await ref.read(activeWorkspaceProvider.notifier).select(ws);
      ref.invalidate(userWorkspacesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .errorCreatingWorkspace(e.toString()))),
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

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ────────────────────────────────────────────
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

            // ── Title ─────────────────────────────────────────────
            Text(
              AppLocalizations.of(context).newWorkspace,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).workspaceDescription,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // ── Type picker ────────────────────────────────────────
            _SectionLabel(label: AppLocalizations.of(context).type),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    icon: '🏠',
                    title: AppLocalizations.of(context).workspacePersonal,
                    subtitle:
                        AppLocalizations.of(context).workspacePersonalSubtitle,
                    selected: _type == WorkspaceType.personal,
                    onTap: () => _onTypeChanged(WorkspaceType.personal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeCard(
                    icon: '👥',
                    title: AppLocalizations.of(context).workspaceShared,
                    subtitle:
                        AppLocalizations.of(context).workspaceSharedSubtitle,
                    selected: _type == WorkspaceType.shared,
                    onTap: () => _onTypeChanged(WorkspaceType.shared),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Name field ─────────────────────────────────────────
            _SectionLabel(label: AppLocalizations.of(context).name),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: _type == WorkspaceType.shared
                    ? AppLocalizations.of(context).workspaceHintShared
                    : AppLocalizations.of(context).workspaceHintPersonal,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final l10n = AppLocalizations.of(context);
                if (v == null || v.trim().isEmpty) return l10n.nameRequired;
                if (v.trim().length < 2) return l10n.nameTooShort;
                if (v.trim().length > 50) return l10n.nameTooLong;
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),

            // ── Emoji picker ───────────────────────────────────────
            _SectionLabel(label: AppLocalizations.of(context).icon),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _emojis.map((e) {
                final selected = _selectedEmoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Color picker ───────────────────────────────────────
            _SectionLabel(label: AppLocalizations.of(context).color),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _kAccentColors.map((c) {
                final selected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: colorScheme.outline, width: 3)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // ── Submit ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppLocalizations.of(context).createWorkspace),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _TypeCard
// ─────────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: colorScheme.primary, width: 2)
              : Border.all(color: colorScheme.outlineVariant, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _SectionLabel
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
