// lib/features/space/create_space_sheet.dart
// Bottom sheet to create a new Space.
// Follows the same patterns as create_workspace_sheet.dart.
//
// Flow:
//   Page 0 — Type picker + Name + Emoji + Color
//   Page 1 — (optional) Invite step via email
//
// After creation: seeds default categories, switches to new space, pops sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/space.dart';
import '../../core/providers/space_providers.dart';

// ─────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────

class CreateSpaceSheet extends ConsumerStatefulWidget {
  const CreateSpaceSheet._();

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const CreateSpaceSheet._(),
      );

  @override
  ConsumerState<CreateSpaceSheet> createState() => _CreateSpaceSheetState();
}

class _CreateSpaceSheetState extends ConsumerState<CreateSpaceSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();

  SpaceType _type         = SpaceType.household;
  String?   _selectedEmoji;
  String?   _selectedColor;
  bool      _loading      = false;
  int       _page         = 0; // 0 = details, 1 = invite

  // Invite state
  final List<String> _pendingInvites = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  String get _emoji => _selectedEmoji ?? _type.defaultEmoji;

  // ── Accent colors (same palette as create_workspace_sheet) ──────
  static const _colors = [
    '#6366F1', // indigo
    '#0EA5E9', // sky
    '#10B981', // emerald
    '#F59E0B', // amber
    '#EF4444', // red
    '#8B5CF6', // violet
  ];

  // ── Emoji palettes per type ──────────────────────────────────────
  static const _emojiPalettes = <SpaceType, List<String>>{
    SpaceType.household: ['🏠','🏡','🛋️','🏗️','🔑','🪴','🧹','💡','🛏️','🚿'],
    SpaceType.trip:      ['✈️','🏖️','🏕️','🗺️','🎒','🚢','🚂','🏔️','🌴','🧳'],
    SpaceType.project:   ['💼','📊','🎯','🖥️','🔧','⚙️','📐','🔬','🚀','💡'],
    SpaceType.family:    ['👨‍👩‍👧','👪','❤️','🎂','🎁','🏡','🌻','👶','🎓','🐾'],
    SpaceType.business:  ['🏢','💹','📈','🤝','💰','🏦','⚖️','📋','🖊️','🔒'],
  };

  // ── Submission ───────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(spaceRepositoryProvider);

      final space = await repo.createSpace(
        name:  _nameCtrl.text.trim(),
        type:  _type,
        emoji: _emoji,
        color: _selectedColor,
      );

      // Seed default categories for the chosen type
      await repo.createDefaultCategories(space.id, _type);

      // Send invites if the user added any on page 1
      for (final email in _pendingInvites) {
        await repo.createInvite(
          spaceId:       space.id,
          invitedEmail:  email,
          role:          SpaceRole.member,
        );
      }

      // Switch to the newly created space
      ref.read(activeSpaceProvider.notifier).select(space);
      ref.invalidate(userSpacesProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar espaço: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      builder: (_, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Column(
            children: [
              // ── Handle ──────────────────────────────────────────
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      _page == 0 ? 'Novo espaço' : 'Convidar pessoas',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),

              // ── Content ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 24),
                  child: Form(
                    key: _formKey,
                    child: _page == 0
                        ? _buildDetailsPage(theme)
                        : _buildInvitePage(theme),
                  ),
                ),
              ),

              // ── Footer buttons ───────────────────────────────────
              _buildFooter(theme, bottom),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Page 0 — Details
  // ─────────────────────────────────────────────────────────────────

  Widget _buildDetailsPage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Type picker ──────────────────────────────────────────
        _sectionLabel('Tipo de espaço', theme),
        const SizedBox(height: 8),
        _TypePicker(
          selected: _type,
          onChanged: (t) => setState(() {
            _type = t;
            _selectedEmoji = null; // reset emoji to new type default
          }),
        ),
        const SizedBox(height: 24),

        // ── Name ────────────────────────────────────────────────
        _sectionLabel('Nome', theme),
        const SizedBox(height: 8),
        TextFormField(
          controller:  _nameCtrl,
          decoration: InputDecoration(
            hintText:       'Ex: Casa dos Roommates',
            border:         const OutlineInputBorder(),
            prefixIcon:     Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Digite um nome';
            if (v.trim().length > 60) return 'Máximo 60 caracteres';
            return null;
          },
        ),
        const SizedBox(height: 24),

        // ── Emoji ────────────────────────────────────────────────
        _sectionLabel('Emoji', theme),
        const SizedBox(height: 8),
        _EmojiPicker(
          emojis:   _emojiPalettes[_type]!,
          selected: _emoji,
          onPick:   (e) => setState(() => _selectedEmoji = e),
        ),
        const SizedBox(height: 24),

        // ── Color ────────────────────────────────────────────────
        _sectionLabel('Cor do espaço', theme),
        const SizedBox(height: 8),
        _ColorPicker(
          colors:   _colors,
          selected: _selectedColor,
          onPick:   (c) => setState(() => _selectedColor = c),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Page 1 — Invite
  // ─────────────────────────────────────────────────────────────────

  Widget _buildInvitePage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adicione pessoas ao espaço "${_nameCtrl.text.trim()}".',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),

        _sectionLabel('E-mail', theme),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  hintText: 'fulano@exemplo.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _addPendingInvite(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: _addPendingInvite,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ],
        ),

        if (_pendingInvites.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel('Será convidado(a)', theme),
          const SizedBox(height: 8),
          ..._pendingInvites.map((email) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                title: Text(email),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () => setState(() => _pendingInvites.remove(email)),
                ),
              )),
        ],

        const SizedBox(height: 12),
        Text(
          'Você também pode convidar depois, nas configurações do espaço.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _addPendingInvite() {
    final email = _emailCtrl.text.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) return;
    if (_pendingInvites.contains(email)) return;
    setState(() {
      _pendingInvites.add(email);
      _emailCtrl.clear();
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // Footer
  // ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(ThemeData theme, double bottom) {
    return Container(
      color: theme.colorScheme.surface,
      padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + bottom),
      child: Row(
        children: [
          // Back / Skip
          if (_page == 1)
            TextButton(
              onPressed: () => setState(() => _page = 0),
              child: const Text('Voltar'),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),

          // Primary action
          _page == 0
              ? FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _page = 1);
                    }
                  },
                  child: const Text('Próximo'),
                )
              : Row(
                  children: [
                    TextButton(
                      onPressed: _loading ? null : _submit,
                      child: const Text('Pular'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Criar espaço'),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label, ThemeData theme) => Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.4,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
// Type Picker
// ─────────────────────────────────────────────────────────────────

class _TypePicker extends StatelessWidget {
  final SpaceType selected;
  final ValueChanged<SpaceType> onChanged;

  const _TypePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SpaceType.values.map((t) {
        final active = t == selected;
        return InkWell(
          onTap: () => onChanged(t),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.defaultEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  t.label,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Emoji Picker
// ─────────────────────────────────────────────────────────────────

class _EmojiPicker extends StatelessWidget {
  final List<String> emojis;
  final String selected;
  final ValueChanged<String> onPick;

  const _EmojiPicker({
    required this.emojis,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: emojis.map((e) {
        final active = e == selected;
        return GestureDetector(
          onTap: () => onPick(e),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44, height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(e, style: const TextStyle(fontSize: 20)),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Color Picker
// ─────────────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final List<String> colors;
  final String? selected;
  final ValueChanged<String> onPick;

  const _ColorPicker({
    required this.colors,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((hex) {
        final color  = _hexToColor(hex);
        final active = hex == selected;
        return GestureDetector(
          onTap: () => onPick(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color:  color,
              shape:  BoxShape.circle,
              border: active
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
              boxShadow: active
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
