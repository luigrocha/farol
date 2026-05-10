# Plan: Budget Intelligence Layer (Financial Copilot)
**Area**: Domain · Analytics · UI
**Priority**: P6 — the final product touch
**Dependencies**: `forecasting.md` (complete) · `recurring_rules.md` (Phase 2+) · `installments_redesign.md` (Phase 2+)
**Impacted files**: New files in `lib/core/domain/`, new widgets in the dashboard

---

## 🔍 Context and Motivation

### What the product needs

Farol with Financial Engine + Forecasting is already better than 95% of finance apps. The Intelligence Layer is what transforms Farol from "great tool" to "indispensable financial copilot."

The difference:
- **Tool**: "You spent R$840 on Entertainment this month"
- **Copilot**: "You are 43% above your usual pace in Entertainment — at this rate, you'll exceed your budget in 8 days"

### Principle: Not AI, but contextual intelligence

This layer is **100% deterministic and rule-based**. No LLM, no ML models, no external API calls. It is a set of expert rules that operate on the user's real data.

This guarantees:
- Works offline
- Reproducible and explainable results
- Zero cost per request
- No hallucinations

ML can be added in v2+ as an additional layer, but the deterministic rules are the foundation.

---

## 📐 Intelligence Layer Architecture

### Insight structure

```dart
class FinancialInsight {
  final String id;
  final InsightType type;
  final InsightPriority priority;   // critical | warning | info | achievement
  final String title;               // short, max 40 chars
  final String body;                // detailed explanation
  final String? actionLabel;        // "View Entertainment" | "Adjust budget" | null
  final String? actionRoute;        // route to navigate on tap
  final double confidence;          // 0.0 – 1.0
  final Map<String, dynamic> data;  // supporting data (for debug and analytics)
  final DateTime generatedAt;
  final DateTime? expiresAt;        // some insights have an expiry date
  final bool isDismissable;
  final String? dismissGroup;       // when dismissed, dismisses all in the group
}

enum InsightType {
  // Preventive alerts (red/orange)
  overdraftRisk,        // risk of closing the period with a negative balance
  liquidityAlert,       // tight cash in the next 7 days
  budgetOverrun,        // category will exceed the budget

  // Detected patterns (yellow)
  spendingSpike,        // spending well above historical pace in a category
  subscriptionCreep,    // subscriptions have grown in the last 3 months
  duplicateCharge,      // probable duplicate charge
  unusualMerchant,      // first purchase at this merchant for a high amount

  // Opportunities (blue/green)
  savingsOpportunity,   // category with recurring excess vs. historical = possible savings
  earlyPayoff,          // early payment would reduce installment months
  investmentOpportunity,// free balance > threshold → suggestion to invest

  // Achievements (green)
  budgetStreak,         // N consecutive periods within budget
  savingsRecord,        // best savings in history
  debtReduction,        // active installments have reduced significantly
  categoryUnderControl, // problem category returned to normal
}

enum InsightPriority { critical, warning, info, achievement }
```

### Engine Rules (the 12 core rules)

```dart
class IntelligenceLayer {

  // RULE 1: Risk of negative balance at end of period
  FinancialInsight? _checkOverdraftRisk(FinancialSnapshot snapshot) {
    final projected = snapshot.projection?.projectedClosingBalance;
    if (projected == null || !projected.isNegative) return null;

    return FinancialInsight(
      type: InsightType.overdraftRisk,
      priority: InsightPriority.critical,
      title: 'Risk of negative balance',
      body: 'At the current pace, you will close the period at ${projected.formatted}. '
            'There are ${snapshot.totalFutureObligations.formatted} in confirmed obligations.',
      actionLabel: 'View projection',
      actionRoute: '/analytics/cashflow',
      confidence: 0.85,
      expiresAt: snapshot.period.end,  // expires at end of period
    );
  }

  // RULE 2: Critical liquidity in the next 7 days
  FinancialInsight? _checkLiquidityAlert(FinancialSnapshot snapshot) {
    final risk = snapshot.projection?.liquidityRisk;
    if (risk == null || risk.index < LiquidityRisk.medium.index) return null;

    final next7Days = snapshot.upcomingPayments
        .where((p) => p.daysFromNow <= 7)
        .map((p) => p.amount)
        .fold(Money.zero, (a, b) => a + b);

    return FinancialInsight(
      type: InsightType.liquidityAlert,
      priority: risk == LiquidityRisk.critical
          ? InsightPriority.critical
          : InsightPriority.warning,
      title: risk == LiquidityRisk.critical ? 'Very tight week' : 'Tight week',
      body: 'You have ${snapshot.currentBalance.formatted} available and '
            '${next7Days.formatted} in payments this week.',
      confidence: 0.95,
    );
  }

  // RULE 3: Category above historical pace (spike)
  List<FinancialInsight> _checkSpendingSpikes(FinancialSnapshot snapshot) {
    return snapshot.categoryVelocities
        .where((v) => v.deviationPercent > 40 && v.currentSpend.amount > 30)
        .map((v) => FinancialInsight(
          type: InsightType.spendingSpike,
          priority: InsightPriority.warning,
          title: 'Spending spike in ${v.category.name}',
          body: '${v.currentSpend.formatted} so far vs. average of '
                '${v.historicalAverage.formatted}. '
                '${v.deviationPercent.round()}% above usual.',
          actionLabel: 'View ${v.category.name}',
          confidence: 0.80,
          data: {'categoryId': v.category.id, 'deviation': v.deviationPercent},
        ))
        .toList();
  }

  // RULE 4: Probable duplicate charge
  List<FinancialInsight> _detectDuplicates(List<Expense> recentExpenses) {
    final candidates = <FinancialInsight>[];
    final groups = _groupSimilarExpenses(recentExpenses);

    for (final group in groups) {
      if (group.length < 2) continue;
      final sorted = group..sort((a, b) => a.date.compareTo(b.date));
      final daysBetween = sorted.last.date.difference(sorted.first.date).inDays;

      if (daysBetween <= 3 && group.length >= 2) {
        candidates.add(FinancialInsight(
          type: InsightType.duplicateCharge,
          priority: InsightPriority.warning,
          title: 'Possible duplicate charge',
          body: '${group.length}x "${group.first.storeDescription}" '
                'for ${group.first.amount.formatted} within $daysBetween days.',
          actionLabel: 'Review',
          confidence: _calculateDuplicateConfidence(group, daysBetween),
          isDismissable: true,
          dismissGroup: 'duplicate_${group.first.storeDescription}',
        ));
      }
    }
    return candidates;
  }

  // RULE 5: Growing subscriptions (subscription creep)
  FinancialInsight? _checkSubscriptionCreep(
    List<List<Envelope>> lastThreePeriods,
  ) {
    const subscriptionCategory = 'subscriptions';
    final amounts = lastThreePeriods
        .map((envelopes) => envelopes
            .firstWhereOrNull((e) => e.category.slug == subscriptionCategory)
            ?.spent ?? Money.zero)
        .toList();

    if (amounts.length < 3) return null;
    final growth = (amounts.last.amount - amounts.first.amount);
    if (growth < 50) return null;  // growth < R$50 is not relevant

    return FinancialInsight(
      type: InsightType.subscriptionCreep,
      priority: InsightPriority.info,
      title: 'Subscriptions growing',
      body: 'Your subscription spending has increased '
            '${FinancialCalculatorService.formatBRL(growth)} '
            'over the last 3 periods.',
      actionLabel: 'View subscriptions',
      confidence: 0.75,
    );
  }

  // RULE 6: Savings opportunity (category with recurring excess)
  List<FinancialInsight> _findSavingsOpportunities(
    List<EnvelopeStatus> envelopes,
    List<List<Envelope>> history,
  ) {
    return envelopes
        .where((e) => e.isOverspent && e.overspentAmount.amount > 50)
        .where((e) => _isChronicallyOverspent(e.category.id, history))
        .map((e) => FinancialInsight(
          type: InsightType.savingsOpportunity,
          priority: InsightPriority.info,
          title: 'Possible savings in ${e.category.name}',
          body: 'You tend to spend ${e.overspentAmount.formatted} above your '
                'budget in ${e.category.name}. Adjusting the budget or '
                'reducing spending could free up ${e.overspentAmount.formatted}/period.',
          actionLabel: 'Adjust budget',
          confidence: 0.65,
        ))
        .toList();
  }

  // RULE 7: Investment opportunity (projected free balance > R$500)
  FinancialInsight? _checkInvestmentOpportunity(FinancialSnapshot snapshot) {
    final predicted = snapshot.projection?.predictedSavings;
    if (predicted == null || predicted.amount < 500) return null;

    return FinancialInsight(
      type: InsightType.investmentOpportunity,
      priority: InsightPriority.info,
      title: 'You\'ll have ${predicted.formatted} left over',
      body: 'Based on your current pace, you\'ll have ${predicted.formatted} '
            'free at the end of the period. How about putting some aside?',
      actionLabel: 'View options',
      confidence: 0.70,
    );
  }

  // RULE 8: Achievement — N periods within budget
  FinancialInsight? _checkBudgetStreak(List<FinancialSnapshot> history) {
    final consecutiveUnderBudget = history
        .takeWhile((s) => !s.envelopes.any((e) => e.isOverspent))
        .length;

    if (consecutiveUnderBudget < 2) return null;

    return FinancialInsight(
      type: InsightType.budgetStreak,
      priority: InsightPriority.achievement,
      title: '$consecutiveUnderBudget periods within budget! 🎉',
      body: 'You\'ve been keeping your finances on track for '
            '$consecutiveUnderBudget consecutive periods.',
      confidence: 1.0,
      isDismissable: true,
    );
  }

  // RULE 9: Best savings in history
  FinancialInsight? _checkSavingsRecord(
    Money currentSavings,
    List<Money> historicalSavings,
  ) {
    if (historicalSavings.isEmpty) return null;
    final previousBest = historicalSavings.reduce(
        (a, b) => a.amount > b.amount ? a : b);

    if (currentSavings <= previousBest) return null;

    return FinancialInsight(
      type: InsightType.savingsRecord,
      priority: InsightPriority.achievement,
      title: 'Savings record! 🏆',
      body: 'This period you are saving ${currentSavings.formatted} — '
            'your best result in ${historicalSavings.length} periods.',
      confidence: 1.0,
    );
  }

  // RULE 10: Debt reduction (active installments decreased)
  FinancialInsight? _checkDebtReduction(
    Money currentInstallmentTotal,
    Money previousInstallmentTotal,
  ) {
    final reduction = previousInstallmentTotal - currentInstallmentTotal;
    if (reduction.amount < 200) return null;  // reduction < R$200 is not relevant

    return FinancialInsight(
      type: InsightType.debtReduction,
      priority: InsightPriority.achievement,
      title: 'Installments decreasing!',
      body: 'Your active installments dropped ${reduction.formatted} '
            'over the last 2 months.',
      confidence: 0.9,
    );
  }

  // RULE 11: Problem category returned to normal
  FinancialInsight? _checkCategoryRecovery(
    CategoryVelocity velocity,
    List<CategoryVelocity> lastPeriod,
  ) {
    final previous = lastPeriod.firstWhereOrNull(
        (v) => v.category.id == velocity.category.id);
    if (previous == null) return null;
    if (previous.deviationPercent <= 30) return null;  // it wasn't problematic
    if (velocity.deviationPercent > 10) return null;   // still problematic

    return FinancialInsight(
      type: InsightType.categoryUnderControl,
      priority: InsightPriority.achievement,
      title: '${velocity.category.name} under control 👍',
      body: 'Last period ${velocity.category.name} was '
            '${previous.deviationPercent.round()}% above normal. '
            'This period it\'s within the usual pace.',
      confidence: 0.80,
    );
  }

  // RULE 12: Unknown merchant for a high value
  FinancialInsight? _checkUnusualMerchant(
    Expense expense,
    List<Expense> history,
  ) {
    if (expense.amount.amount < 200) return null;  // only for amounts > R$200
    final knownMerchants = history
        .map((e) => e.storeDescription?.toLowerCase())
        .whereNotNull()
        .toSet();

    final merchantKey = expense.storeDescription?.toLowerCase();
    if (merchantKey == null || knownMerchants.contains(merchantKey)) return null;

    return FinancialInsight(
      type: InsightType.unusualMerchant,
      priority: InsightPriority.info,
      title: 'New high-value purchase',
      body: '"${expense.storeDescription}" for ${expense.amount.formatted} — '
            'first time this appears in your history.',
      actionLabel: 'View expense',
      confidence: 0.85,
      isDismissable: true,
    );
  }
}
```

### Orchestrator: analysis and prioritization

```dart
class IntelligenceLayer {
  static const _maxInsightsVisible = 3;
  static const _minConfidence = 0.60;

  List<FinancialInsight> analyze({
    required FinancialSnapshot current,
    required List<FinancialSnapshot> history,
    required List<Expense> recentExpenses,
  }) {
    final raw = <FinancialInsight>[];

    // Run all rules
    _checkOverdraftRisk(current)?.let(raw.add);
    _checkLiquidityAlert(current)?.let(raw.add);
    raw.addAll(_checkSpendingSpikes(current));
    raw.addAll(_detectDuplicates(recentExpenses));
    _checkSubscriptionCreep(history.map((s) => s.envelopes).toList())?.let(raw.add);
    raw.addAll(_findSavingsOpportunities(current.envelopes, history.map((s) => s.envelopes).toList()));
    _checkInvestmentOpportunity(current)?.let(raw.add);
    _checkBudgetStreak(history)?.let(raw.add);
    // ... remaining rules

    return raw
        .where((i) => i.confidence >= _minConfidence)
        .where((i) => !_isDismissed(i))       // filter dismissed by user
        .sorted(_byPriority)                   // critical first
        .take(_maxInsightsVisible)             // maximum 3 visible
        .toList();
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
```

---

## ⚡ Impact Analysis

### Files to create
```
lib/core/domain/entities/financial_insight.dart
lib/core/domain/services/intelligence_layer.dart
lib/core/repositories/dismissed_insights_repository.dart  ← persists dismissals
lib/features/insights/insights_panel.dart                 ← dashboard widget
lib/features/insights/insight_card.dart
lib/features/insights/insights_screen.dart                ← "View all"
```

### Files to modify
```
lib/core/domain/entities/financial_snapshot.dart  ← insights: List<FinancialInsight>
lib/features/dashboard/dashboard_screen.dart       ← InsightsPanel widget
lib/features/dashboard/widgets/alert_banner.dart   ← replaced by InsightsPanel
```

---

## 🗺️ Incremental Strategy

### PHASE 1 — Foundation: Entities + Basic Rules ✅ COMPLETE
**Goal**: Infrastructure + the 4 highest-impact rules.
**Reversibility**: 100% — new code.

```
Task 1.1: FinancialInsight entity + InsightType + InsightPriority enums

Task 1.2: DismissedInsightsRepository
  - Persist in UserSettings (Drift): key = 'dismissed_insights', value = JSON array
  - isDismissed(insightId | dismissGroup): bool
  - dismiss(insightId, dismissGroup?)
  - clearExpired()

Task 1.3: IntelligenceLayer — 4 core rules
  1. _checkOverdraftRisk() — critical, high activation frequency
  2. _checkLiquidityAlert() — critical, based on LiquidityRisk from Forecasting
  3. _checkSpendingSpikes() — warning, most useful in daily use
  4. _checkInvestmentOpportunity() — info, positive engagement

Task 1.4: Integrate IntelligenceLayer in FinancialEngine
  - snapshot.insights = intelligenceLayer.analyze(current, history, recentExpenses)
```

---

### PHASE 2 — InsightsPanel on Dashboard ✅ COMPLETE
**Goal**: Insights appear in the UI in a non-invasive way.

```
Task 2.1: InsightCard widget
  - Priority icon (🔴 critical / 🟡 warning / 🔵 info / 🟢 achievement)
  - Bold title + summarized body
  - Action button (if available)
  - X button to dismiss (if isDismissable)

Task 2.2: InsightsPanel widget
  - Shows maximum 3 InsightCards
  - If more: "View all (N)" link
  - If no insights: renders nothing (zero height)
  - Dashboard position: below PeriodBalanceHero, above KPIs

Task 2.3: InsightsScreen (View all)
  - Full list of active insights
  - Grouped by priority
  - Dismissed insights visible with "Restore" option

Task 2.4: Replace existing AlertBanner
  - The current AlertBanner (budget alert) is absorbed by InsightsPanel
  - Remove AlertBanner after InsightsPanel is stable
```

---

### PHASE 3 — Advanced Rules ✅ COMPLETE
**Goal**: The remaining 8 rules.

```
Task 3.1: _detectDuplicates() — duplicate charge
Task 3.2: _checkSubscriptionCreep() — growing subscriptions
Task 3.3: _findSavingsOpportunities() — possible savings
Task 3.4: _checkBudgetStreak() — consistency achievement
Task 3.5: _checkSavingsRecord() — best savings
Task 3.6: _checkDebtReduction() — decreasing installments
Task 3.7: _checkCategoryRecovery() — category returned to normal
Task 3.8: _checkUnusualMerchant() — unusual purchase
```

---

### PHASE 4 — Insight Analytics ✅ COMPLETE (2026-05-08)
**Goal**: Measure whether insights are useful.

```
Task 4.1: InsightStats entity + DismissedInsightsRepository.trackDismiss() + getStats()
  - Stored in UserSettings (Drift): key 'insight_dismissal_stats'
  - insightStatsProvider in providers.dart

Task 4.2: InsightCard calls trackDismiss + invalidates insightStatsProvider on dismiss

Task 4.3: InsightsScreen displays "Most ignored types" section for types with ≥2 dismissals
```

---

## 🚨 Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Too many simultaneous insights → user ignores everything | High | Uselessness | Maximum 3 visible + strict priority |
| Irrelevant insights generate distrust | High | Feature abandonment | High confidence threshold + dismiss option |
| Technical or scary language | Medium | User anxiety | Copy review for each insight: human, actionable, no jargon |
| IntelligenceLayer overloads ForecastingEngine | Medium | Performance | Calculate insights in background after snapshot; cache TTL 10min |
| Badly calibrated critical alerts (false positive) | Medium | Loss of trust | Test each rule with synthetic data before production |
| "Duplicate charge" flags legitimate transactions | High | Frustration | Threshold: same store + same amount + ≤3 days → base confidence 0.70, only suggests at 0.70+ |

---

## ✅ Completion Checklist

### Phase 1 — Foundation ✅ 2026-05-08
- [x] Complete `FinancialInsight` entity
- [x] `DismissedInsightsRepository` with Drift persistence
- [x] 4 core rules implemented and tested
- [x] Integrated in `FinancialSnapshot`

### Phase 2 — UI ✅ 2026-05-08
- [x] `InsightCard` widget with all visual states
- [x] `InsightsPanel` in dashboard (maximum 3)
- [x] `InsightsScreen` to view all
- [x] Old `AlertBanner` removed

### Phase 3 — Advanced Rules ✅ 2026-05-08
- [x] All 12 rules implemented
- [ ] Each rule tested with synthetic data (true positive + false positive)
- [ ] Dismiss rate < 40% in real use (relevance indicator)

### Phase 4 — Analytics ✅ 2026-05-08
- [x] `InsightStats` entity + `trackDismiss()` + `getStats()` in `DismissedInsightsRepository`
- [x] `insightStatsProvider` in `providers.dart`
- [x] `InsightCard` calls `trackDismiss` + invalidates `insightStatsProvider` on dismiss
- [x] `InsightsScreen` shows "Most ignored types" for types with ≥2 dismissals
- [ ] Threshold adjustment based on real data
- [ ] Alert preferences in Settings
- [x] Documented in `docs/decisions/007-intelligence-layer.md`

---

## 📎 References

- Detailed analysis: `FAROL_PREDICTIVE_ENGINE.md` → Section 8
- ADR: `docs/decisions/007-intelligence-layer.md`
- Depends on: `forecasting.md` (complete) · `recurring_rules.md` · `installments_redesign.md`
- Enables: v2 — Intelligence with contextual LLM (out of current scope)
