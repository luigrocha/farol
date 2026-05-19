// lib/features/space/add_space_transaction_sheet.dart
// Bottom sheet to add a shared expense to the active Space.
//
// Features:
//   • Amount + description + date
//   • Space category picker
//   • "Paid by" member picker (defaults to current user)
//   • Split rule selector: equal / custom / percentage / solo
//   • Per-member amount inputs when rule ≠ equal
//   • Ledger link toggle ("Add my share to personal budget")
//
// On submit: creates the transaction, then optionally calls linkToLedger
// for the current user's share if the toggle is on.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/space.dart';
import '../../core/models/space_transaction.dart';
import '../../core/providers/space_providers.dart';

final _brlFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

// ─────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────

class AddSpaceTransactionSheet extends ConsumerStatefulWidget {
  final Space space;

  const AddSpaceTransactionSheet._({required this.space});

  static Future<void> show(BuildContext context, Space space) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddSpaceTransactionSheet._(space: space),
      );

  @override
  ConsumerState<AddSpaceTransactionSheet> createState() =>
      _AddSpaceTransactionSheetState();
}

class _AddSpaceTransactionSheetState
    extends ConsumerState<AddSpaceTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  SpaceCategory? _category;
  SplitRule _splitRule = SplitRule.equal;
  DateTime _date = DateTime.now();
  String? _paidBy; // null → current user
  bool _linkLedger = true;
  bool _loading = false;

  // Per-member share amounts for custom/percentage rules
  // key = userId, value = controller
  final Map<String, TextEditingController> _shareCtrl = {};

  String get _currentUserId => Supabase.instance.client.auth.currentUser!.id;
  Space get _space => widget.space;

  @override
  void initState() {
    super.initState();
    _paidBy = _currentUserId;
    // Pre-create a controller per member for custom split
    for (final m in _space.members) {
      _shareCtrl[m.userId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _shareCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Computed shares ──────────────────────────────────────────────

  double get _totalAmount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0.0;

  Map<String, double> _computeShares() {
    final members = _space.members;
    final total = _totalAmount;

    switch (_splitRule) {
      case SplitRule.equal:
        if (members.isEmpty) return {};
        final each = _round(total / members.length);
        // Assign remainder to payer to keep exact sum
        final base = <String, double>{
          for (final m in members) m.userId: each,
        };
        final sumBase = base.values.fold(0.0, (a, b) => a + b);
        final diff = _round(total - sumBase);
        final payerId = _paidBy ?? _currentUserId;
        base[payerId] = _round((base[payerId] ?? 0) + diff);
        return base;

      case SplitRule.solo:
        return {_paidBy ?? _currentUserId: total};

      case SplitRule.custom:
      case SplitRule.percentage:
        final shares = <String, double>{};
        for (final m in members) {
          final raw = double.tryParse(
                _shareCtrl[m.userId]?.text.replaceAll(',', '.') ?? '',
              ) ??
              0.0;
          shares[m.userId] = _splitRule == SplitRule.percentage
              ? _round(total * raw / 100)
              : raw;
        }
        return shares;
    }
  }

  double _round(double v) => (v * 100).round() / 100;

  // ── Submit ───────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final shares = _computeShares();
    final total = _totalAmount;
    final sharesSum = shares.values.fold(0.0, (a, b) => a + b);

    if ((sharesSum - total).abs() > 0.02) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A soma das partes (${_brlFormatter.format(sharesSum)}) '
            'não bate com o total (${_brlFormatter.format(total)}).',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(spaceRepositoryProvider);

      final tx = await repo.createTransaction(
        spaceId: _space.id,
        categoryId: _category?.id,
        amount: total,
        description: _descCtrl.text.trim(),
        date: _date,
        splitRule: _splitRule,
        sharesPerUser: shares,
        paidBy: _paidBy,
      );

      // If user wants to track their share in the personal ledger
      if (_linkLedger) {
        final myShare =
            tx.shares.where((s) => s.userId == _currentUserId).firstOrNull;
        if (myShare != null) {
          await repo.linkToLedger(
            spaceId: _space.id,
            shareId: myShare.id,
            amount: myShare.amount,
            date: _date,
          );
        }
      }

      // Invalidate the transactions list for this space
      ref.invalidate(spaceTransactionsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
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
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final categoriesAsync = ref.watch(spaceCategoriesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                  width: 40,
                  height: 4,
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
                      '${_space.emoji ?? ''} Novo gasto'.trim(),
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

              // ── Scrollable form ──────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount
                        _sectionLabel('Valor', theme),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountCtrl,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixText: 'R\$ ',
                            hintText: '0,00',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9,.]')),
                          ],
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Digite o valor';
                            }
                            final n = double.tryParse(v.replaceAll(',', '.'));
                            if (n == null || n <= 0) return 'Valor inválido';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        _sectionLabel('Descrição', theme),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Ex: Aluguel de maio',
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Digite uma descrição';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Category
                        _sectionLabel('Categoria', theme),
                        const SizedBox(height: 8),
                        categoriesAsync.when(
                          data: (cats) => _CategoryPicker(
                            categories: cats,
                            selected: _category,
                            onPick: (c) => setState(() => _category = c),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 16),

                        // Date
                        _sectionLabel('Data', theme),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18),
                                const SizedBox(width: 8),
                                Text(DateFormat('dd/MM/yyyy').format(_date)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Paid by
                        if (_space.members.length > 1) ...[
                          _sectionLabel('Quem pagou', theme),
                          const SizedBox(height: 8),
                          _PaidByPicker(
                            members: _space.members,
                            selected: _paidBy ?? _currentUserId,
                            onPick: (uid) => setState(() => _paidBy = uid),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Split rule
                        _sectionLabel('Divisão', theme),
                        const SizedBox(height: 8),
                        _SplitRulePicker(
                          selected: _splitRule,
                          onChanged: (r) => setState(() => _splitRule = r),
                        ),
                        const SizedBox(height: 16),

                        // Per-member inputs for custom / percentage
                        if (_splitRule == SplitRule.custom ||
                            _splitRule == SplitRule.percentage) ...[
                          _sectionLabel(
                            _splitRule == SplitRule.percentage
                                ? 'Percentuais (%)'
                                : 'Valores (R\$)',
                            theme,
                          ),
                          const SizedBox(height: 8),
                          _ShareInputList(
                            members: _space.members,
                            controllers: _shareCtrl,
                            isPercentage: _splitRule == SplitRule.percentage,
                            total: _totalAmount,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Ledger link toggle
                        _LedgerLinkTile(
                          enabled: _linkLedger,
                          myAmount: _computeShares()[_currentUserId] ?? 0,
                          onChanged: (v) => setState(() => _linkLedger = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Footer ──────────────────────────────────────────
              Container(
                color: theme.colorScheme.surface,
                padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + bottom),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar gasto'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Date picker ──────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // ── Helpers ──────────────────────────────────────────────────────

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
// Category Picker — horizontal scroll chips
// ─────────────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  final List<SpaceCategory> categories;
  final SpaceCategory? selected;
  final ValueChanged<SpaceCategory?> onPick;

  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final active = cat.id == selected?.id;
          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cat.icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child:
                        Text(cat.icon!, style: const TextStyle(fontSize: 14)),
                  ),
                Text(cat.name),
              ],
            ),
            selected: active,
            onSelected: (_) => onPick(active ? null : cat),
            selectedColor: theme.colorScheme.primaryContainer,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Paid By Picker
// ─────────────────────────────────────────────────────────────────

class _PaidByPicker extends StatelessWidget {
  final List<SpaceMember> members;
  final String selected;
  final ValueChanged<String> onPick;

  const _PaidByPicker({
    required this.members,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: members.map((m) {
        final active = m.userId == selected;
        final initials = m.userId.substring(0, 2).toUpperCase();
        return ChoiceChip(
          avatar: CircleAvatar(
            backgroundColor: _avatarColor(m.userId),
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          label: Text(m.userId == selected ? 'Você' : 'Outro'),
          selected: active,
          onSelected: (_) => onPick(m.userId),
          selectedColor: theme.colorScheme.primaryContainer,
        );
      }).toList(),
    );
  }

  Color _avatarColor(String userId) {
    final colors = [
      Colors.teal,
      Colors.indigo,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.green,
    ];
    return colors[userId.codeUnitAt(0) % colors.length];
  }
}

// ─────────────────────────────────────────────────────────────────
// Split Rule Picker — segmented button
// ─────────────────────────────────────────────────────────────────

class _SplitRulePicker extends StatelessWidget {
  final SplitRule selected;
  final ValueChanged<SplitRule> onChanged;

  const _SplitRulePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SplitRule>(
      segments: const [
        ButtonSegment(
          value: SplitRule.equal,
          label: Text('Igualmente'),
          icon: Icon(Icons.people, size: 16),
        ),
        ButtonSegment(
          value: SplitRule.custom,
          label: Text('Personalizado'),
          icon: Icon(Icons.edit, size: 16),
        ),
        ButtonSegment(
          value: SplitRule.percentage,
          label: Text('%'),
          icon: Icon(Icons.percent, size: 16),
        ),
        ButtonSegment(
          value: SplitRule.solo,
          label: Text('Só eu'),
          icon: Icon(Icons.person, size: 16),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Share Input List (custom / percentage)
// ─────────────────────────────────────────────────────────────────

class _ShareInputList extends StatelessWidget {
  final List<SpaceMember> members;
  final Map<String, TextEditingController> controllers;
  final bool isPercentage;
  final double total;

  const _ShareInputList({
    required this.members,
    required this.controllers,
    required this.isPercentage,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: members.map((m) {
        final ctrl = controllers[m.userId]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(
                  m.userId.substring(0, 2).toUpperCase(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixText: isPercentage ? '%' : 'R\$',
                    hintText: isPercentage ? '50' : '0,00',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Ledger Link Toggle
// ─────────────────────────────────────────────────────────────────

class _LedgerLinkTile extends StatelessWidget {
  final bool enabled;
  final double myAmount;
  final ValueChanged<bool> onChanged;

  const _LedgerLinkTile({
    required this.enabled,
    required this.myAmount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        value: enabled,
        onChanged: onChanged,
        secondary: Icon(
          Icons.account_balance_wallet_outlined,
          color: enabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          'Registrar no meu orçamento',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: myAmount > 0
            ? Text(
                'Adiciona ${_brlFormatter.format(myAmount)} ao seu orçamento pessoal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
      ),
    );
  }
}
