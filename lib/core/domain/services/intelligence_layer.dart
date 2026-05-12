import '../entities/envelope.dart';
import '../entities/financial_insight.dart';
import '../entities/financial_projection.dart';
import '../entities/financial_snapshot.dart';
import '../entities/liquidity_risk.dart';
import '../value_objects/money.dart';
import '../../models/expense.dart';

/// All 12 deterministic rules. Pure service — no I/O.
class IntelligenceLayer {
  static const int maxVisible = 3;
  static const double minConfidence = 0.60;

  const IntelligenceLayer();

  List<FinancialInsight> analyze({
    required FinancialSnapshot snapshot,
    required FinancialProjection? projection,
    required List<Expense> recentExpenses,
    required List<Expense> allExpenses,
    required Set<String> dismissedIds,
    int? consecutiveUnderBudgetPeriods,
    double? previousInstallmentTotal,
  }) {
    final raw = <FinancialInsight>[];

    // ── Critical ────────────────────────────────────────────────────────────
    _rule1OverdraftRisk(snapshot, projection)?.let(raw.add);
    _rule2LiquidityAlert(snapshot, projection)?.let(raw.add);

    // ── Warnings ────────────────────────────────────────────────────────────
    raw.addAll(_rule3SpendingSpikes(snapshot, allExpenses));
    raw.addAll(_rule4DuplicateCharges(recentExpenses));
    _rule5SubscriptionCreep(allExpenses)?.let(raw.add);

    // ── Opportunities ────────────────────────────────────────────────────────
    raw.addAll(_rule6SavingsOpportunities(snapshot));
    _rule7InvestmentOpportunity(snapshot, projection)?.let(raw.add);

    // ── Achievements ────────────────────────────────────────────────────────
    _rule8BudgetStreak(consecutiveUnderBudgetPeriods)?.let(raw.add);
    _rule10DebtReduction(
            snapshot, previousInstallmentTotal)
        ?.let(raw.add);
    raw.addAll(_rule12UnusualMerchants(recentExpenses, allExpenses));

    final filtered = raw
        .where((i) => i.confidence >= minConfidence)
        .where((i) => !i.isExpired())
        .where((i) => !_isDismissed(i, dismissedIds))
        .toList()
      ..sort(_byPriority);
    return filtered.take(maxVisible).toList();
  }

  // ── RULE 1: Overdraft risk ────────────────────────────────────────────────

  FinancialInsight? _rule1OverdraftRisk(
      FinancialSnapshot snap, FinancialProjection? proj) {
    final projected = proj?.projectedClosingBalance;
    if (projected == null || !projected.isNegative) return null;
    return FinancialInsight(
      id: 'overdraft_${snap.period.start.millisecondsSinceEpoch}',
      type: InsightType.overdraftRisk,
      priority: InsightPriority.critical,
      titleKey: 'insight_overdraft_title',
      bodyKey: 'insight_overdraft_body',
      actionKey: 'insight_overdraft_action',
      title: '⚠️ Você pode fechar no vermelho',
      body:
          'No ritmo atual, o período fecha em ${projected.formatted}. '
          'Ainda tem ${snap.totalFutureObligations.formatted} em contas a pagar.',
      actionLabel: 'Ver projeção →',
      actionRoute: '/analytics',
      confidence: 0.85,
      expiresAt: snap.period.end,
      data: {
        'projectedAmount': projected.amount,
        'projectedFormatted': projected.formatted,
        'obligationsFormatted': snap.totalFutureObligations.formatted,
      },
    );
  }

  // ── RULE 2: Liquidity alert ───────────────────────────────────────────────

  FinancialInsight? _rule2LiquidityAlert(
      FinancialSnapshot snap, FinancialProjection? proj) {
    final risk = proj?.liquidityRisk;
    if (risk == null || !risk.isAtRisk) return null;
    final isCritical = risk.level == LiquidityRiskLevel.critical;
    return FinancialInsight(
      id: 'liquidity_${snap.period.start.millisecondsSinceEpoch}',
      type: InsightType.liquidityAlert,
      priority:
          isCritical ? InsightPriority.critical : InsightPriority.warning,
      titleKey: isCritical ? 'insight_liquidity_critical_title' : 'insight_liquidity_warning_title',
      bodyKey: 'insight_liquidity_body',
      actionKey: 'insight_liquidity_action',
      actionRoute: '/analytics',
      title: isCritical ? '🚨 Crítico: pagamentos vencem esta semana' : '📅 Pagamentos vencem esta semana',
      body:
          'Seu saldo atual é ${snap.currentBalance.formatted}. '
          'Verifique se cobre todos os vencimentos antes de gastar.',
      actionLabel: 'Ver compromissos →',
      confidence: 0.95,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      data: {
        'riskLevel': risk.level.name,
        'balanceFormatted': snap.currentBalance.formatted,
        'obligationsFormatted': risk.obligationsNext7Days.formatted,
      },
    );
  }

  // ── RULE 3: Spending spikes ───────────────────────────────────────────────

  List<FinancialInsight> _rule3SpendingSpikes(
      FinancialSnapshot snap, List<Expense> allExpenses) {
    final velocities = _computeCategoryVelocities(snap, allExpenses);
    return velocities
        .where((v) => v.deviationPercent > 40 && v.currentSpend.amount > 30)
        .map((v) => FinancialInsight(
              id: 'spike_${v.categorySlug}_${snap.period.start.millisecondsSinceEpoch}',
              type: InsightType.spendingSpike,
              priority: InsightPriority.warning,
              titleKey: 'insight_spike_title',
              bodyKey: 'insight_spike_body',
              actionKey: 'insight_spike_action',
              title: 'Aceleração em ${v.categoryName}',
              body:
                  '${v.currentSpend.formatted} até agora vs. média de '
                  '${v.historicalAverage.formatted}. '
                  '${v.deviationPercent.round()}% acima do usual.',
              actionLabel: 'Ver ${v.categoryName}',
              confidence: 0.80,
              data: {
                'category': v.categorySlug,
                'deviation': v.deviationPercent,
                'currentFormatted': v.currentSpend.formatted,
                'averageFormatted': v.historicalAverage.formatted,
                'deviationPct': '${v.deviationPercent.round()}',
              },
            ))
        .toList();
  }

  // ── RULE 4: Duplicate charges ─────────────────────────────────────────────

  List<FinancialInsight> _rule4DuplicateCharges(List<Expense> recent) {
    final groups = <String, List<Expense>>{};
    for (final e in recent) {
      final desc = (e.storeDescription ?? '').toLowerCase().trim();
      if (desc.isEmpty) continue;
      final key = '$desc|${(e.amount * 100).round()}';
      groups.putIfAbsent(key, () => []).add(e);
    }

    final insights = <FinancialInsight>[];
    for (final group in groups.values) {
      if (group.length < 2) continue;
      final sorted = [...group]
        ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
      final days = sorted.last.transactionDate
          .difference(sorted.first.transactionDate)
          .inDays;
      if (days > 3) continue;

      final confidence = days == 0 ? 0.90 : (days <= 1 ? 0.80 : 0.70);
      final desc = group.first.storeDescription ?? group.first.category;
      insights.add(FinancialInsight(
        id: 'dup_${desc}_${sorted.first.transactionDate.millisecondsSinceEpoch}',
        type: InsightType.duplicateCharge,
        priority: InsightPriority.warning,
        titleKey: 'insight_duplicate_title',
        bodyKey: 'insight_duplicate_body',
        actionKey: 'insight_duplicate_action',
        title: 'Possível cobrança duplicada',
        body:
            '${group.length}x "$desc" por '
            'R\$ ${group.first.amount.toStringAsFixed(2)} em $days dia${days == 1 ? '' : 's'}.',
        actionLabel: 'Verificar',
        confidence: confidence,
        isDismissable: true,
        dismissGroup: 'dup_$desc',
        data: {
          'count': group.length,
          'days': days,
          'desc': desc,
          'amountFormatted': group.first.amount.toStringAsFixed(2),
        },
      ));
    }
    return insights;
  }

  // ── RULE 5: Subscription creep ────────────────────────────────────────────

  FinancialInsight? _rule5SubscriptionCreep(List<Expense> all) {
    // Compare subscriptions spending last 3 months
    final now = DateTime.now();
    final months = [
      (now.month, now.year),
      (now.month - 1 <= 0 ? now.month + 11 : now.month - 1,
          now.month - 1 <= 0 ? now.year - 1 : now.year),
      (now.month - 2 <= 0 ? now.month + 10 : now.month - 2,
          now.month - 2 <= 0 ? now.year - 1 : now.year),
    ];

    final monthlyTotals = months.map((pair) {
      final (m, y) = pair;
      return all
          .where((e) =>
              e.month == m &&
              e.year == y &&
              (e.category.contains('subscription') ||
                  e.category.contains('streaming')))
          .fold(0.0, (s, e) => s + e.amount);
    }).toList();

    if (monthlyTotals.length < 3) return null;
    final growth = monthlyTotals[0] - monthlyTotals[2];
    if (growth < 50) return null;

    return FinancialInsight(
      id: 'sub_creep_${now.year}_${now.month}',
      type: InsightType.subscriptionCreep,
      priority: InsightPriority.info,
      titleKey: 'insight_subscription_title',
      bodyKey: 'insight_subscription_body',
      actionKey: 'insight_subscription_action',
      title: 'Assinaturas crescendo',
      body:
          'Seus gastos com assinaturas aumentaram '
          'R\$ ${growth.toStringAsFixed(2)} nos últimos 3 meses.',
      actionLabel: 'Ver assinaturas',
      confidence: 0.75,
      isDismissable: true,
      data: {
        'growth': growth,
        'growthFormatted': growth.toStringAsFixed(2),
      },
    );
  }

  // ── RULE 6: Savings opportunities ────────────────────────────────────────

  List<FinancialInsight> _rule6SavingsOpportunities(FinancialSnapshot snap) {
    return snap.envelopes
        .where((e) =>
            e.status == EnvelopeStatus.overspent &&
            (e.spent - e.effectiveAllocated).amount > 50)
        .map((e) {
          final overspent = e.spent - e.effectiveAllocated;
          return FinancialInsight(
            id: 'save_${e.category.slug}_${snap.period.start.millisecondsSinceEpoch}',
            type: InsightType.savingsOpportunity,
            priority: InsightPriority.info,
            titleKey: 'insight_savings_title',
            bodyKey: 'insight_savings_body',
            actionKey: 'insight_savings_action',
            title: 'Economia possível em ${e.category.name}',
            body: '${e.category.name} está ${overspent.formatted} '
                'acima do orçamento. Ajustar pode liberar essa quantia por período.',
            actionLabel: 'Ajustar orçamento',
            confidence: 0.65,
            data: {
              'category': e.category.slug,
              'categoryName': e.category.name,
              'overspentFormatted': overspent.formatted,
            },
          );
        })
        .toList();
  }

  // ── RULE 7: Investment opportunity ───────────────────────────────────────

  FinancialInsight? _rule7InvestmentOpportunity(
      FinancialSnapshot snap, FinancialProjection? proj) {
    final closing = proj?.projectedClosingBalance;
    if (closing == null || closing.amount < 500) return null;
    return FinancialInsight(
      id: 'invest_${snap.period.start.millisecondsSinceEpoch}',
      type: InsightType.investmentOpportunity,
      priority: InsightPriority.info,
      titleKey: 'insight_invest_title',
      bodyKey: 'insight_invest_body',
      actionKey: 'insight_invest_action',
      title: 'Você vai sobrar ${closing.formatted}',
      body:
          'Com base no ritmo atual, você terá ${closing.formatted} '
          'livres no final do período. Que tal destinar uma parte?',
      actionLabel: 'Ver opções',
      confidence: 0.70,
      isDismissable: true,
      data: {
        'amount': closing.amount,
        'amountFormatted': closing.formatted,
      },
    );
  }

  // ── RULE 8: Budget streak ─────────────────────────────────────────────────

  FinancialInsight? _rule8BudgetStreak(int? streakCount) {
    if (streakCount == null || streakCount < 2) return null;
    return FinancialInsight(
      id: 'streak_$streakCount',
      type: InsightType.budgetStreak,
      priority: InsightPriority.achievement,
      titleKey: 'insight_streak_title',
      bodyKey: 'insight_streak_body',
      title: '$streakCount períodos dentro do orçamento! 🎉',
      body:
          'Você está mantendo suas finanças sob controle por '
          '$streakCount períodos consecutivos. Continue assim!',
      confidence: 1.0,
      isDismissable: true,
      data: {'streak': streakCount},
    );
  }

  // ── RULE 10: Debt reduction ───────────────────────────────────────────────

  FinancialInsight? _rule10DebtReduction(
      FinancialSnapshot snap, double? previousTotal) {
    if (previousTotal == null) return null;
    final current = snap.totalFutureObligations.amount;
    final reduction = previousTotal - current;
    if (reduction < 200) return null;
    return FinancialInsight(
      id: 'debt_reduction_${snap.period.start.millisecondsSinceEpoch}',
      type: InsightType.debtReduction,
      priority: InsightPriority.achievement,
      titleKey: 'insight_debt_title',
      bodyKey: 'insight_debt_body',
      title: 'Parcelas reduzindo!',
      body:
          'Suas parcelas ativas caíram '
          'R\$ ${reduction.toStringAsFixed(2)} em relação ao período anterior.',
      confidence: 0.90,
      isDismissable: true,
      data: {
        'reduction': reduction,
        'reductionFormatted': reduction.toStringAsFixed(2),
      },
    );
  }

  // ── RULE 12: Unusual merchant ─────────────────────────────────────────────

  List<FinancialInsight> _rule12UnusualMerchants(
      List<Expense> recent, List<Expense> all) {
    final insights = <FinancialInsight>[];
    for (final e in recent) {
      if (e.amount < 200) continue;
      final desc = e.storeDescription?.toLowerCase();
      if (desc == null) continue;
      // Known if appeared in older history (not just recent)
      final inOlderHistory =
          all.any((h) => h.id != e.id && h.storeDescription?.toLowerCase() == desc);
      if (inOlderHistory) continue;

      insights.add(FinancialInsight(
        id: 'unusual_${e.id}',
        type: InsightType.unusualMerchant,
        priority: InsightPriority.info,
        titleKey: 'insight_unusual_title',
        bodyKey: 'insight_unusual_body',
        actionKey: 'insight_unusual_action',
        title: 'Nova compra de alto valor',
        body:
            '"${e.storeDescription}" por R\$ ${e.amount.toStringAsFixed(2)} — '
            'primeira vez que aparece no seu histórico.',
        actionLabel: 'Ver gasto',
        confidence: 0.85,
        isDismissable: true,
        dismissGroup: 'unusual_${e.storeDescription}',
        data: {
          'expenseId': e.id,
          'desc': e.storeDescription ?? '',
          'amountFormatted': e.amount.toStringAsFixed(2),
        },
      ));
    }
    return insights;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<CategoryVelocity> _computeCategoryVelocities(
      FinancialSnapshot snap, List<Expense> all) {
    final now = DateTime.now();

    // Current period spend by category
    final current = <String, double>{};
    for (final e in all.where((e) =>
        e.year == now.year && e.month == now.month && !e.isProjected)) {
      current[e.category] = (current[e.category] ?? 0) + e.amount;
    }

    // Historical average (last 3 months)
    final historical = <String, List<double>>{};
    for (int i = 1; i <= 3; i++) {
      final dt = DateTime(now.year, now.month - i, 1);
      for (final e in all.where((e) =>
          e.year == dt.year && e.month == dt.month && !e.isProjected)) {
        historical.putIfAbsent(e.category, () => []).add(e.amount);
      }
    }

    final result = <CategoryVelocity>[];
    for (final entry in current.entries) {
      final hist = historical[entry.key] ?? [];
      if (hist.isEmpty) continue;
      final avg = hist.reduce((a, b) => a + b) / hist.length;
      result.add(CategoryVelocity(
        categorySlug: entry.key,
        categoryName: entry.key, // UI layer can resolve to display name
        currentSpend: Money.fromDouble(entry.value),
        historicalAverage: Money.fromDouble(avg),
      ));
    }
    return result;
  }

  bool _isDismissed(FinancialInsight i, Set<String> dismissed) {
    if (dismissed.contains(i.id)) return true;
    if (i.dismissGroup != null && dismissed.contains(i.dismissGroup)) {
      return true;
    }
    return false;
  }

  int _byPriority(FinancialInsight a, FinancialInsight b) {
    const order = [
      InsightPriority.critical,
      InsightPriority.warning,
      InsightPriority.info,
      InsightPriority.achievement,
    ];
    return order.indexOf(a.priority).compareTo(order.indexOf(b.priority));
  }
}

extension _NullableExt<T> on T? {
  void let(void Function(T) fn) {
    if (this != null) fn(this as T);
  }
}
