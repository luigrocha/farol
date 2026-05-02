import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/account.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../design/widgets/farol_card.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('Contas',
            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
        iconTheme: IconThemeData(color: colors.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz_rounded, color: colors.onSurface),
            tooltip: 'Transferência entre contas',
            onPressed: () {
              final accounts = accountsAsync.value ?? [];
              if (accounts.length < 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Adicione ao menos 2 contas para transferir')),
                );
                return;
              }
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => _TransferSheet(accounts: accounts),
              );
            },
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (accounts) {
          if (accounts.isEmpty) return const _EmptyState();
          final liquid = accounts.where((a) => a.accountType.isLiquid).toList();
          final fgtsList = accounts.where((a) => !a.accountType.isLiquid).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (liquid.isNotEmpty) ...[
                const _SectionHeader(label: 'Contas Bancárias'),
                const SizedBox(height: 8),
                ...liquid.map((a) => _AccountTile(account: a)),
              ],
              if (fgtsList.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _SectionHeader(label: 'FGTS'),
                const SizedBox(height: 8),
                ...fgtsList.map((a) => _AccountTile(account: a)),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_accounts',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _AddAccountSheet(),
        ),
        backgroundColor: tokens.FarolColors.beam,
        child: const Icon(Icons.add, color: tokens.FarolColors.navy),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.colors.onSurfaceSoft));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.account_balance_outlined, size: 64, color: colors.onSurfaceFaint),
        const SizedBox(height: 16),
        Text('Nenhuma conta cadastrada',
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: colors.onSurfaceMuted)),
        const SizedBox(height: 8),
        Text('Adicione suas contas para acompanhar\nseu patrimônio em tempo real.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.onSurfaceSoft)),
      ]),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  final Account account;
  const _AccountTile({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FarolCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceLow,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(account.accountType.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(account.name,
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
            Text(account.institution,
                style: GoogleFonts.manrope(fontSize: 12, color: colors.onSurfaceSoft)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              'R\$ ${account.currentBalance.toStringAsFixed(2).replaceAll('.', ',')}',
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurface),
            ),
            Text(account.accountType.label,
                style: GoogleFonts.manrope(fontSize: 11, color: colors.onSurfaceSoft)),
          ]),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: colors.onSurfaceFaint),
            onSelected: (action) {
              if (action == 'edit') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _EditBalanceSheet(account: account),
                );
              } else if (action == 'delete') {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Excluir conta?'),
                    content: Text('A conta "${account.name}" será removida.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () {
                          ref.read(accountNotifierProvider.notifier).delete(account.id);
                          Navigator.pop(context);
                        },
                        child: const Text('Excluir', style: TextStyle(color: tokens.FarolColors.coral)),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Atualizar saldo')),
              const PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// ADD ACCOUNT SHEET
// ═══════════════════════════════════════════

class _AddAccountSheet extends ConsumerStatefulWidget {
  const _AddAccountSheet();

  @override
  ConsumerState<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<_AddAccountSheet> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _institution = 'Nubank';
  AccountType _type = AccountType.checking;
  bool _saving = false;

  static const _institutions = [
    'Nubank', 'Itaú', 'Santander', 'Bradesco', 'Inter', 'Mercado Pago',
    'Caixa', 'Banco do Brasil', 'C6 Bank', 'XP', 'Outro',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final balance = double.tryParse(_balanceController.text.replaceAll(',', '.')) ?? 0.0;
      await ref.read(accountNotifierProvider.notifier).insert(
            name: name,
            institution: _institution,
            type: _type.dbValue,
            initialBalance: balance,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nova Conta',
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome da conta', hintText: 'ex: Conta Corrente'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _institution,
              decoration: const InputDecoration(labelText: 'Instituição'),
              items: _institutions.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
              onChanged: (v) => setState(() => _institution = v!),
            ),
            const SizedBox(height: 12),
            Text('Tipo de conta', style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft)),
            const SizedBox(height: 6),
            SegmentedButton<AccountType>(
              segments: AccountType.values.map((t) => ButtonSegment(
                value: t,
                label: Text(t.label, style: const TextStyle(fontSize: 11)),
              )).toList(),
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
              decoration: const InputDecoration(labelText: 'Saldo inicial', prefixText: 'R\$ '),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Salvar'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// EDIT BALANCE SHEET
// ═══════════════════════════════════════════

class _EditBalanceSheet extends ConsumerStatefulWidget {
  final Account account;
  const _EditBalanceSheet({required this.account});

  @override
  ConsumerState<_EditBalanceSheet> createState() => _EditBalanceSheetState();
}

class _EditBalanceSheetState extends ConsumerState<_EditBalanceSheet> {
  late final TextEditingController _balanceController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(
        text: widget.account.currentBalance.toStringAsFixed(2).replaceAll('.', ','));
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final balance = double.tryParse(_balanceController.text.replaceAll(',', '.'));
    if (balance == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(accountNotifierProvider.notifier).updateBalance(widget.account.id, balance);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Atualizar Saldo', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
            Text(widget.account.name, style: TextStyle(fontSize: 13, color: colors.onSurfaceSoft)),
            const SizedBox(height: 20),
            TextField(
              controller: _balanceController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
              decoration: const InputDecoration(labelText: 'Saldo atual', prefixText: 'R\$ '),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Salvar'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// TRANSFER SHEET
// ═══════════════════════════════════════════

class _TransferSheet extends ConsumerStatefulWidget {
  final List<Account> accounts;
  const _TransferSheet({required this.accounts});

  @override
  ConsumerState<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<_TransferSheet> {
  late int _fromId;
  late int _toId;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fromId = widget.accounts.first.id;
    _toId = widget.accounts.length > 1 ? widget.accounts[1].id : widget.accounts.first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0 || _fromId == _toId) return;
    setState(() => _saving = true);
    try {
      await ref.read(transferNotifierProvider.notifier).transfer(
            fromAccountId: _fromId,
            toAccountId: _toId,
            amount: amount,
            date: _date,
            description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transferência registrada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = widget.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.accountType.emoji} ${a.name}'))).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Transferência Interna',
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
            const SizedBox(height: 4),
            Text('Não aparece em receitas/despesas', style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft)),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: _fromId,
              decoration: const InputDecoration(labelText: 'De'),
              items: items,
              onChanged: (v) => setState(() => _fromId = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _toId,
              decoration: const InputDecoration(labelText: 'Para'),
              items: items,
              onChanged: (v) => setState(() => _toId = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
              decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Transferir'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
