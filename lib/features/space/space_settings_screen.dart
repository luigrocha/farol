// lib/features/space/space_settings_screen.dart
// Settings screen for a Space.
//
// Sections:
//   • Identity — rename, emoji, color, description
//   • Members — shortcut to SpaceMembersScreen
//   • Invite — copy invite link
//   • Danger zone — archive space

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/space.dart';
import '../../core/providers/space_providers.dart';
import 'space_members_screen.dart';

class SpaceSettingsScreen extends ConsumerStatefulWidget {
  final Space space;

  const SpaceSettingsScreen({super.key, required this.space});

  static Future<void> push(BuildContext context, Space space) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SpaceSettingsScreen(space: space),
        ),
      );

  @override
  ConsumerState<SpaceSettingsScreen> createState() =>
      _SpaceSettingsScreenState();
}

class _SpaceSettingsScreenState extends ConsumerState<SpaceSettingsScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  late SpaceType   _type;
  late String?     _emoji;
  late String?     _color;
  bool             _saving = false;
  bool             _dirty  = false;

  static const _colors = [
    '#6366F1', '#0EA5E9', '#10B981',
    '#F59E0B', '#EF4444', '#8B5CF6',
  ];

  static const _emojiPalettes = <SpaceType, List<String>>{
    SpaceType.household: ['🏠','🏡','🛋️','🏗️','🔑','🪴','🧹','💡','🛏️','🚿'],
    SpaceType.trip:      ['✈️','🏖️','🏕️','🗺️','🎒','🚢','🚂','🏔️','🌴','🧳'],
    SpaceType.project:   ['💼','📊','🎯','🖥️','🔧','⚙️','📐','🔬','🚀','💡'],
    SpaceType.family:    ['👨‍👩‍👧','👪','❤️','🎂','🎁','🏡','🌻','👶','🎓','🐾'],
    SpaceType.business:  ['🏢','💹','📈','🤝','💰','🏦','⚖️','📋','🖊️','🔒'],
  };

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.space.name);
    _descCtrl = TextEditingController(text: widget.space.description ?? '');
    _type  = widget.space.type;
    _emoji = widget.space.emoji;
    _color = widget.space.color;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String get _currentEmoji => _emoji ?? _type.defaultEmoji;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(spaceRepositoryProvider)
          .updateSpaceIdentity(
            widget.space.id,
            name:        name,
            emoji:       _currentEmoji,
            color:       _color,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            type:        _type,
          );

      // Refresh active space if it's this one
      final active = ref.read(activeSpaceProvider).valueOrNull;
      if (active?.id == updated.id) {
        ref.read(activeSpaceProvider.notifier).select(updated);
      }
      ref.invalidate(userSpacesProvider);

      if (mounted) {
        setState(() {
          _dirty  = false;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Espaço atualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _copyInviteLink() async {
    try {
      final invite = await ref
          .read(spaceRepositoryProvider)
          .createInvite(
            spaceId:      widget.space.id,
            invitedEmail: '',  // email-less token link (edge function handles)
            role:         SpaceRole.member,
          );
      final token = invite['token'] as String? ?? '';
      final link  = 'https://farol.app/join/$token';
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copiado para a área de transferência')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar link: $e')),
        );
      }
    }
  }

  Future<void> _archiveSpace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Arquivar espaço?'),
        content: Text(
          'O espaço "${widget.space.name}" será arquivado. '
          'Nenhum dado será perdido, mas ele não aparecerá mais na lista.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(spaceRepositoryProvider).archiveSpace(widget.space.id);
      ref.invalidate(userSpacesProvider);

      // Clear active space if it was this one
      final active = ref.read(activeSpaceProvider).valueOrNull;
      if (active?.id == widget.space.id) {
        ref.read(activeSpaceProvider.notifier).select(null);
      }

      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isOwner = ref.watch(currentUserSpaceRoleProvider).isOwner;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configurações',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_dirty && isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Identity ────────────────────────────────────────────
          _sectionHeader('Identidade', theme),

          // Emoji + Name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji picker popover
              _EmojiButton(
                emoji:   _currentEmoji,
                emojis:  _emojiPalettes[_type]!,
                onPick: (e) {
                  setState(() => _emoji = e);
                  _markDirty();
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  enabled:    isOwner,
                  decoration: const InputDecoration(
                    labelText: 'Nome do espaço',
                    border:    OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _markDirty(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          TextField(
            controller: _descCtrl,
            enabled:    isOwner,
            decoration: const InputDecoration(
              labelText: 'Descrição (opcional)',
              border:    OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (_) => _markDirty(),
          ),
          const SizedBox(height: 16),

          // Color picker
          Text(
            'Cor',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: _colors.map((hex) {
              final color  = _hexColor(hex);
              final active = hex == _color;
              return GestureDetector(
                onTap: isOwner
                    ? () {
                        setState(() => _color = hex);
                        _markDirty();
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color:  color,
                    shape:  BoxShape.circle,
                    border: active
                        ? Border.all(
                            color: theme.colorScheme.onSurface,
                            width: 3,
                          )
                        : null,
                    boxShadow: active
                        ? [BoxShadow(color: color.withOpacity(0.45), blurRadius: 6)]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Members shortcut ─────────────────────────────────────
          _sectionHeader('Membros', theme),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.group_outlined),
              title: Text(
                '${widget.space.members.length} '
                '${widget.space.members.length == 1 ? 'membro' : 'membros'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => SpaceMembersScreen.push(context, widget.space),
            ),
          ),
          const SizedBox(height: 24),

          // ── Invite ───────────────────────────────────────────────
          _sectionHeader('Convite', theme),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.link_outlined),
              title: const Text('Copiar link de convite'),
              subtitle: const Text('Qualquer pessoa com o link pode entrar como membro'),
              onTap: isOwner ? _copyInviteLink : null,
            ),
          ),
          const SizedBox(height: 32),

          // ── Danger zone ──────────────────────────────────────────
          if (isOwner) ...[
            _sectionHeader('Zona de perigo', theme, danger: true),
            Card(
              margin: EdgeInsets.zero,
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              child: ListTile(
                leading: Icon(
                  Icons.archive_outlined,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Arquivar espaço',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: const Text('O espaço deixará de aparecer na lista'),
                onTap: _archiveSpace,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, ThemeData theme, {bool danger = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: danger
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );

  static Color _hexColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ─────────────────────────────────────────────────────────────────
// Emoji button with inline picker popover
// ─────────────────────────────────────────────────────────────────

class _EmojiButton extends StatefulWidget {
  final String emoji;
  final List<String> emojis;
  final ValueChanged<String> onPick;

  const _EmojiButton({
    required this.emoji,
    required this.emojis,
    required this.onPick,
  });

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Container(
            width: 56, height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:        theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: _open
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: Text(widget.emoji, style: const TextStyle(fontSize: 26)),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        theme.colorScheme.surface,
              border:       Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset:     const Offset(0, 2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 4, runSpacing: 4,
              children: widget.emojis.map((e) => GestureDetector(
                onTap: () {
                  widget.onPick(e);
                  setState(() => _open = false);
                },
                child: Container(
                  width: 36, height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: e == widget.emoji
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 20)),
                ),
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
