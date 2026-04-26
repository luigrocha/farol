import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../core/theme/farol_colors.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/i18n/app_localizations.dart';
import '../../core/widgets/farol_snackbar.dart';
import '../auth/presentation/auth_providers.dart';
import '../budget/domain/budget_settings.dart';
import '../budget/presentation/budget_settings_sheet.dart';
import '../budget/presentation/budget_goals_sheet.dart';
import '../net_worth/presentation/net_worth_settings_sheet.dart';
import '../profile/presentation/profile_providers.dart';
import 'salary_settings_sheet.dart';
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surfaceLow,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text('Farol', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            actions: const [Icon(Icons.settings_outlined, size: 22), SizedBox(width: 24)],
          ),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const _ProfileCard(),
              const SizedBox(height: 16),
              const _BudgetSection(),
              const SizedBox(height: 16),
              const _SalarySection(),
              const SizedBox(height: 24),
              const _NetWorthSection(),
              const SizedBox(height: 24),
              const _Section(title: 'Language / Idioma', icon: Icons.public, children: [
                _LangRow(flag: '🇪🇸', name: 'Español', sub: 'España', locale: Locale('es')),
                _LangRow(flag: '🇧🇷', name: 'Português', sub: 'Brasil', locale: Locale('pt')),
                _LangRow(flag: '🇺🇸', name: 'English', sub: 'United States', locale: Locale('en')),
              ]),
              const SizedBox(height: 24),
              const _AppearanceCard(),
              const SizedBox(height: 24),
              const _SimulatorsSection(),
              const SizedBox(height: 24),
              const _ExportSection(),
              const SizedBox(height: 24),
              const _SupportSection(),
              const SizedBox(height: 28),
              Center(child: TextButton.icon(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout, color: tokens.FarolColors.coral, size: 16),
                label: Text(l10n.signOut, style: const TextStyle(color: tokens.FarolColors.coral, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(height: 40),
            ]))),
        ],
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final profileAsync = ref.watch(currentProfileProvider);
    final displayName = profileAsync.whenOrNull(data: (p) => p?.displayName) ?? '';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.translate('profile').toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: colors.onSurfaceFaint)),
        const SizedBox(height: 6),
        Text(
          displayName.isNotEmpty ? displayName : '—',
          style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: colors.onSurface),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed('/edit_profile'),
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.FarolColors.navy, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(l10n.editProfile, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        const _PeriodSettingsRow(),
      ]),
    );
  }
}

class _PeriodSettingsRow extends ConsumerWidget {
  const _PeriodSettingsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final period = ref.watch(currentPeriodProvider);
    final settings = ref.watch(budgetSettingsProvider).value;
    final cutoffDay = settings?.cutoffDay ?? 1;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CutoffDaySheet(currentDay: cutoffDay),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, size: 18, color: colors.onSurfaceSoft),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).translate('financial_period'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  Text(period.label,
                      style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceSoft),
          ],
        ),
      ),
    );
  }
}

class _CutoffDaySheet extends ConsumerStatefulWidget {
  final int currentDay;
  const _CutoffDaySheet({required this.currentDay});

  @override
  ConsumerState<_CutoffDaySheet> createState() => _CutoffDaySheetState();
}

class _CutoffDaySheetState extends ConsumerState<_CutoffDaySheet> {
  late int _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentDay;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final current = ref.read(budgetSettingsProvider).value ?? const BudgetSettings();
      await ref.read(budgetSettingsProvider.notifier).save(current.copyWith(cutoffDay: _selected));
      if (mounted) {
        Navigator.of(context).pop();
        context.showSuccessSnackBar(AppLocalizations.of(context).translate('settings_saved'));
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: colors.onSurfaceFaint, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: colors.iconTintBlue, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.calendar_month_outlined, size: 20, color: tokens.FarolColors.navy),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).translate('period_start'), style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('${AppLocalizations.of(context).translate('day_of_each_month').split(' ')[0]} $_selected ${AppLocalizations.of(context).translate('day_of_each_month').split(' ').skip(1).join(' ')}', style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).translate('select_period_start'),
            style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft, height: 1.5),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1,
            ),
            itemCount: 28,
            itemBuilder: (_, i) {
              final day = i + 1;
              final isSelected = day == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected ? tokens.FarolColors.navy : colors.surfaceLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('$day', style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : colors.onSurface,
                    )),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.FarolColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(AppLocalizations.of(context).translate('save'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title; final IconData icon; final List<Widget> children;
  const _Section({required this.title, required this.icon, required this.children});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 16, color: colors.onSurfaceMuted), const SizedBox(width: 8), Text(title, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface))]),
      const SizedBox(height: 12),
      ...children,
    ]);
  }
}

class _LangRow extends ConsumerWidget {
  final String flag, name, sub; final Locale locale;
  const _LangRow({required this.flag, required this.name, required this.sub, required this.locale});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final current = ref.watch(localeProvider);
    final selected = current == locale;
    return GestureDetector(
      onTap: () => ref.read(localeProvider.notifier).setLocale(locale),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? tokens.FarolColors.beam : Colors.transparent, width: 2)),
        child: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: colors.surfaceLow, shape: BoxShape.circle), child: Center(child: Text(flag, style: const TextStyle(fontSize: 18)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface)),
            Text(sub, style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft)),
          ])),
          if (selected) Container(width: 18, height: 18, decoration: const BoxDecoration(color: tokens.FarolColors.beam, shape: BoxShape.circle), child: const Icon(Icons.check, size: 12, color: Colors.white)),
        ]),
      ),
    );
  }
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themeModeProvider);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF244A72), tokens.FarolColors.navy])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.appearance, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        Text(l10n.customizeInterface, style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(99)),
          child: Row(children: [
            _ThemeBtn(label: l10n.translate('light_mode'), icon: Icons.light_mode, active: theme == ThemeMode.light, onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light)),
            _ThemeBtn(label: l10n.translate('dark_mode'), icon: Icons.dark_mode, active: theme == ThemeMode.dark, onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark)),
          ]),
        ),
      ]),
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  final String label; final IconData icon; final bool active; final VoidCallback onTap;
  const _ThemeBtn({required this.label, required this.icon, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: active ? tokens.FarolColors.navy : Colors.white),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: active ? tokens.FarolColors.navy : Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    ));
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String name, sub;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  const _DataRow({required this.icon, required this.name, required this.sub, required this.color, this.onTap, this.isLoading = false});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
            Text(sub, style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
          ])),
          isLoading
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.onSurfaceSoft))
              : Icon(Icons.download_outlined, size: 18, color: colors.onSurfaceSoft),
        ]),
      ),
    );
  }
}

enum _ExportTask { none, transactions, income, backup, pdf }

class _ExportSection extends ConsumerStatefulWidget {
  const _ExportSection();
  @override
  ConsumerState<_ExportSection> createState() => _ExportSectionState();
}

class _ExportSectionState extends ConsumerState<_ExportSection> {
  _ExportTask _loading = _ExportTask.none;

  Future<void> _run(_ExportTask task, Future<void> Function() fn) async {
    if (_loading != _ExportTask.none) return;
    setState(() => _loading = task);
    try {
      await fn();
      if (mounted) {
        context.showSuccessSnackBar(AppLocalizations.of(context).translate('export_success'));
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    } finally {
      if (mounted) setState(() => _loading = _ExportTask.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final year = ref.watch(selectedYearProvider);
    final svc = ref.read(exportServiceProvider);
    final colors = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.shield_outlined, size: 16, color: colors.onSurfaceMuted),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).translate('data_privacy'), style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface)),
      ]),
      const SizedBox(height: 12),
      _DataRow(
        icon: Icons.receipt_long_outlined,
        name: AppLocalizations.of(context).translate('export_transactions'),
        sub: 'CSV — $month/$year',
        color: tokens.FarolColors.beam,
        isLoading: _loading == _ExportTask.transactions,
        onTap: () => _run(_ExportTask.transactions, () => svc.exportExpensesToCsv(month, year)),
      ),
      _DataRow(
        icon: Icons.description_outlined,
        name: AppLocalizations.of(context).translate('income_statement'),
        sub: 'CSV — $month/$year',
        color: tokens.FarolColors.navy,
        isLoading: _loading == _ExportTask.income,
        onTap: () => _run(_ExportTask.income, () => svc.exportIncomesToCsv(month, year)),
      ),
      _DataRow(
        icon: Icons.cloud_download_outlined,
        name: AppLocalizations.of(context).translate('full_backup'),
        sub: 'JSON',
        color: tokens.FarolColors.tide,
        isLoading: _loading == _ExportTask.backup,
        onTap: () => _run(_ExportTask.backup, svc.exportBackup),
      ),
      _DataRow(
        icon: Icons.picture_as_pdf,
        name: AppLocalizations.of(context).translate('monthly_report_pdf'),
        sub: 'PDF — $month/$year',
        color: tokens.FarolColors.coral,
        isLoading: _loading == _ExportTask.pdf,
        onTap: () => _run(_ExportTask.pdf,
            () => svc.exportMonthlyReport(month, year, ref.read(budgetSettingsProvider).value)),
      ),
      const _PrivacyToggleRow(),
    ]);
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppLocalizations.of(context).translate('concierge_support'), style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _SupportCard(icon: Icons.chat_bubble_outline, label: AppLocalizations.of(context).translate('chat_24_7'))),
        const SizedBox(width: 10),
        Expanded(child: _SupportCard(icon: Icons.headset_mic_outlined, label: AppLocalizations.of(context).translate('vip_call'))),
      ]),
    ]);
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon; final String label;
  const _SupportCard({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 22, color: tokens.FarolColors.beam)),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurface), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _SalarySection extends ConsumerWidget {
  const _SalarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final salaryAsync = ref.watch(salarySettingsProvider);

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SalarySettingsSheet(),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: colors.surfaceLowest,
            borderRadius: BorderRadius.circular(16)),
        child: salaryAsync.when(
          loading: () => const Center(
              child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))),
          error: (_, __) => Text(l10n.couldNotLoadSalary),
          data: (salary) {
            final hasData = salary != null && salary.grossSalary > 0;
            return Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: hasData
                      ? tokens.FarolColors.beam.withValues(alpha: 0.12)
                      : colors.iconTintBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasData
                      ? Icons.account_balance_outlined
                      : Icons.add,
                  size: 18,
                  color: hasData
                      ? tokens.FarolColors.beam
                      : colors.onSurface,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    hasData ? l10n.translate('salary_configured') : l10n.translate('configure_salary'),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface),
                  ),
                  Text(
                    hasData
                        ? '${l10n.lblGross}: ${FinancialCalculatorService.formatBRL(salary.grossSalary)} · ${l10n.lblNet}: ${FinancialCalculatorService.formatBRL(salary.netSalary)}'
                        : l10n.translate('salary_calculated'),
                    style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft),
                  ),
                ]),
              ),
              Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceSoft),
            ]);
          },
        ),
      ),
    );
  }
}

class _BudgetSection extends ConsumerWidget {
  const _BudgetSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final budgetAsync = ref.watch(budgetSettingsProvider);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.account_balance_wallet_outlined, size: 16, color: colors.onSurfaceMuted),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).translate('monthly_budget'), style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface)),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const BudgetSettingsSheet(),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
          child: budgetAsync.when(
            loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => Text(AppLocalizations.of(context).couldNotLoadBudget),
            data: (budget) {
              final hasData = budget != null && budget.totalBudget > 0;
              return Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: hasData ? colors.secondaryContainer : colors.iconTintBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasData ? Icons.check_circle_outline : Icons.add,
                    size: 18,
                    color: hasData ? tokens.FarolColors.beam : colors.onSurface,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    AppLocalizations.of(context).translate('monthly_budget'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
                  ),
                  Text(
                    hasData
                        ? '${FinancialCalculatorService.formatBRL(budget.totalBudget)} ${AppLocalizations.of(context).perMonth}'
                        : AppLocalizations.of(context).tapConfigureBudgets,
                    style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft),
                  ),
                  if (hasData) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      _BudgetChip(label: AppLocalizations.of(context).salary, value: budget.netSalary),
                      const SizedBox(width: 6),
                      _BudgetChip(label: AppLocalizations.of(context).translate('swile'), value: budget.swileTotal),
                    ]),
                  ],
                ])),
                Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceSoft),
              ]);
            },
          ),
        ),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const BudgetGoalsSheet(),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.iconTintBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.category_outlined, size: 18, color: tokens.FarolColors.navy),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('category_budgets'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
                  ),
                  Text(
                    AppLocalizations.of(context).translate('set_spending_limits'),
                    style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceSoft),
          ]),
        ),
      ),
    ]);
  }
}

class _BudgetChip extends StatelessWidget {
  final String label;
  final double value;
  const _BudgetChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(6)),
      child: Text(
        '$label: ${FinancialCalculatorService.formatBRL(value)}',
        style: TextStyle(fontSize: 10, color: colors.onSurfaceSoft, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _NetWorthSection extends ConsumerWidget {
  const _NetWorthSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final snapAsync = ref.watch(netWorthSnapshotProvider);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.account_balance_outlined, size: 16, color: colors.onSurfaceMuted),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).translate('net_worth'), style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface)),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const NetWorthSettingsSheet(),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
          child: snapAsync.when(
            loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => Text(AppLocalizations.of(context).couldNotLoadNetWorth),
            data: (snap) {
              final hasData = snap != null && (snap.fgtsBalance + snap.investmentsTotal + snap.emergencyFund + snap.patrimonyTotal) > 0;
              final total = hasData
                  ? FinancialCalculatorService.calculateNetWorth(
                      patrimonyTotal: snap.patrimonyTotal,
                      fgtsBalance: snap.fgtsBalance,
                      investmentsTotal: snap.investmentsTotal,
                      emergencyFund: snap.emergencyFund,
                      pendingInstallments: snap.pendingInstallments,
                    )
                  : 0.0;
              return Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: hasData ? colors.secondaryContainer : colors.iconTintBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasData ? Icons.check_circle_outline : Icons.add,
                    size: 18,
                    color: hasData ? tokens.FarolColors.beam : colors.onSurface,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    hasData ? AppLocalizations.of(context).translate('net_worth_configured') : AppLocalizations.of(context).translate('configure_net_worth'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
                  ),
                  Text(
                    hasData
                        ? '${AppLocalizations.of(context).translate("total")}: ${FinancialCalculatorService.formatBRL(total)}'
                        : AppLocalizations.of(context).translate('net_worth_desc'),
                    style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft),
                  ),
                ])),
                Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceSoft),
              ]);
            },
          ),
        ),
      ),
    ]);
  }
}

class _SimulatorsSection extends StatelessWidget {
  const _SimulatorsSection();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.calculate_outlined, size: 16, color: colors.onSurfaceMuted),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context).simulators, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface)),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/thirteenth_salary'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.payments_outlined, size: 18, color: tokens.FarolColors.beam),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).simulator13th, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
              Text(AppLocalizations.of(context).simulator13thDesc, style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
            ])),
            Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceSoft),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/fgts_aniversario'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF006D5B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFF006D5B)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).simulatorFgts, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
              Text(AppLocalizations.of(context).simulatorFgtsDesc, style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
            ])),
            Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceSoft),
          ]),
        ),
      ),
    ]);
  }
}

class _PrivacyToggleRow extends ConsumerWidget {
  const _PrivacyToggleRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isPrivate = ref.watch(privacyModeProvider);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(10)),
          child: Icon(isPrivate ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: colors.onSurface),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppLocalizations.of(context).hideValues, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
          Text(AppLocalizations.of(context).hideValuesDesc, style: TextStyle(fontSize: 11, color: colors.onSurfaceSoft)),
        ])),
        Switch(
          value: isPrivate,
          onChanged: (_) => ref.read(privacyModeProvider.notifier).toggle(),
          activeThumbColor: tokens.FarolColors.navy,
        ),
      ]),
    );
  }
}
