# Plan: UI Provider Migration — Resolução do ui_audit_2026_05_08
**Área**: UI · Providers · Domain
**Prioridade**: P1 — UI polish, sem breaking changes
**Dependências**: Nenhuma (domínio já implementado)
**Origem**: `docs/architecture/ui_audit_2026_05_08.md`

---

## 🔍 Contexto

O motor preditivo está completo. A auditoria identificou 4 pontos onde a UI ainda usa providers/lógica legada em vez do novo domínio. Este plano os resolve de forma incremental, um arquivo por vez.

### Mapa do problema

```
quick_add_bottom_sheet.dart   → categoriesStreamProvider (AsyncValue<List<Category>>)
edit_expense_bottom_sheet.dart → categoriesStreamProvider (AsyncValue<List<Category>>)
                                 ↓ deveria ser
                                 categoriesRefProvider (List<CategoryRef>) — síncrono, nunca null

expense_breakdown.dart        → categoriesMapProvider (Map<String, Category>)
                                 budgetGoalsMapProvider (legacy BudgetGoal)
                                 ↓ deveria ser
                                 categoriesRefProvider para nomes/emojis

health_screen.dart            → cashExpensesProvider + cashRemainingProvider
                                 + installmentsProvider (CardInstallment!)
                                 + FinancialCalculatorService.calculateHealthScore()
                                 ↓ deveria ser
                                 financialSnapshotProvider.healthScore (já calculado)

transactions_screen.dart      → isFixed branch + deleteFixedSeriesFrom()
                                 ↓ deveria ser
                                 link para RecurringRule se expense.recurringRuleId != null
```

### Por que essa ordem?

- **Fase 1** (category pickers) — maior impacto no fluxo mais crítico (criar gasto), menor risco
- **Fase 2** (expense_breakdown) — isolado num widget sem efeitos colaterais
- **Fase 3** (health_screen) — requer análise dos sub-scores que dependem de dados adicionais
- **Fase 4** (isFixed cleanup) — requer verificação de dados em produção antes de remover

---

## ⚡ Análise de Impacto

| Arquivo | Linhas afetadas | Risco | Backward compat? |
|---|---|---|---|
| `quick_add_bottom_sheet.dart` | ~10 linhas | Baixo | Sim — `CategoryRef` tem `id`, `slug`, `name`, `emoji` |
| `edit_expense_bottom_sheet.dart` | ~10 linhas | Baixo | Sim |
| `expense_breakdown.dart` | ~5 linhas | Baixo | Sim — apenas display |
| `health_screen.dart` | ~20 linhas | Médio | Sim — sub-scores parcialmente reaproveitados |
| `transactions_screen.dart` | ~20 linhas | Médio | Sim — manter fallback para isFixed legacy |

### Providers que serão removidos dos arquivos (não deletados, apenas deixados de usar)

- `categoriesStreamProvider` — deixa de ser importado nos bottom sheets
- `categoriesMapProvider` — deixa de ser importado em expense_breakdown
- `cashExpensesProvider`, `cashRemainingProvider`, `installmentsProvider` — deixam de ser usados em health_screen

---

## 🗺️ Fases

---

### FASE 1 — Category Pickers: quick_add + edit_expense
**Objetivo**: Trocar `categoriesStreamProvider` por `categoriesRefProvider` nos dois bottom sheets.
**Reversibilidade**: 100% — mudança de provider, sem alteração de schema ou lógica de negócio.

#### O que muda

`categoriesStreamProvider` retorna `AsyncValue<List<Category>>` — exige `.when(loading, error, data)`.
`categoriesRefProvider` retorna `List<CategoryRef>` — síncrono, sem loading state.

```dart
// ❌ ANTES — quick_add_bottom_sheet.dart
final categoriesAsync = ref.watch(categoriesStreamProvider);
// ... dentro do build:
categoriesAsync.when(
  loading: () => const SizedBox(height: 100, child: CircularProgressIndicator()),
  error: (_, __) => Text('Erro'),
  data: (categories) => GridView(...),
)

// ✅ DEPOIS
final categories = ref.watch(categoriesRefProvider); // List<CategoryRef>, nunca null
// ... direto:
GridView(children: categories.map((c) => _catChip(c, context)).toList())
```

#### Ajuste no `_catChip`

O método `_catChip` recebe `Category` hoje. Mudar para `CategoryRef`:

```dart
// ❌ ANTES
Widget _catChip(Category c, BuildContext context) { ... }

// ✅ DEPOIS
Widget _catChip(CategoryRef c, BuildContext context) { ... }
// CategoryRef tem: c.slug, c.name, c.emoji — mesmos campos usados
```

#### Ajuste no `_save` (quick_add)

```dart
// ❌ ANTES
final categories = ref.read(categoriesStreamProvider).value ?? [];
final currentCat = categories.firstWhere((c) => c.slug == _categoryDbValue,
    orElse: () => categories.isNotEmpty ? categories.first : const Category(...));

// ✅ DEPOIS
final categories = ref.read(categoriesRefProvider);
final currentCat = categories.firstWhere((c) => c.slug == _categoryDbValue,
    orElse: () => categories.isNotEmpty ? categories.first : CategoryRef.uncategorized(_categoryDbValue));
```

#### Ajuste em edit_expense

`edit_expense_bottom_sheet.dart` tem `_subcategories` com chaves UPPERCASE (`'HOUSING'`, `'TRANSPORT'`...).
Ao migrar para `CategoryRef`, os slugs são lowercase (`'housing'`, `'transport'`).
Atualizar as chaves do mapa `_subcategories` para lowercase para consistência.

```dart
// ❌ ANTES
static const _subcategories = {
  'HOUSING': [...],
  'TRANSPORT': [...],
};

// ✅ DEPOIS
static const _subcategories = {
  'housing': [...],
  'transport': [...],
};
```

**Arquivos modificados**:
- `lib/features/transactions/quick_add_bottom_sheet.dart`
- `lib/features/transactions/edit_expense_bottom_sheet.dart`

**Teste de sucesso**: Abrir quick_add → picker de categorias renderiza sem loading state → selecionar categoria custom → gasto criado com categoria correta.

---

### FASE 2 — expense_breakdown: categoriesMapProvider → categoriesRefProvider
**Objetivo**: Widget do dashboard usa `CategoryRef` para nomes/emojis.
**Reversibilidade**: 100% — apenas display.

#### O que muda

```dart
// ❌ ANTES
final catsMap = ref.watch(categoriesMapProvider); // Map<String, Category>
// ...
final catModel = catsMap[catDbValue];
final label = catModel?.name ?? catDbValue;
final emoji = catModel?.emoji ?? '💰';

// ✅ DEPOIS
final catsRef = { for (final c in ref.watch(categoriesRefProvider)) c.slug: c };
// ...
final catRef = catsRef[catDbValue];
final label = catRef?.name ?? catDbValue;
final emoji = catRef?.emoji ?? '💰';
```

**Nota**: `budgetGoalsMapProvider` continua sendo usado para os targets de orçamento por categoria. Migrá-lo para `envelopesProvider` é escopo de outra iteração (requer remapear a lógica de `goal.targetAmount` → `envelope.effectiveAllocated`).

**Arquivos modificados**:
- `lib/features/dashboard/widgets/expense_breakdown.dart`

**Teste de sucesso**: Dashboard mostra categorias custom com nome e emoji corretos na lista de despesas por categoria.

---

### FASE 3 — health_screen: migração para financialSnapshotProvider
**Objetivo**: Eliminar o recálculo manual do healthScore e os providers legados.
**Reversibilidade**: Alta — dados estão todos no snapshot.

#### Análise dos sub-scores

A tela exibe 5 sub-scores com barras de pontuação. Nem todos vêm direto do snapshot:

| Sub-score | Fonte atual | Nova fonte |
|---|---|---|
| Score geral (0–10) | `FinancialCalculatorService.calculateHealthScore()` | `snapshot.healthScore` ✅ |
| Taxa de poupança | `(net - cash) / net * 100` | `snapshot.savingsRate * 100` ✅ |
| Balanço mensal | `cashRemainingProvider` | `snapshot.currentBalance.amount` ✅ |
| Parcelas / salário | `installmentsProvider` (CardInstallment) → `monthlyAmount` | `snapshot.totalFutureObligations.amount / snapshot.cashIncome.amount * 100` ✅ |
| Habitação / salário | `byCategory['HOUSING'] / net` | `cashExpensesByCategoryProvider['housing']` (manter por agora) ⚠️ |
| Fundo de emergência | `netWorthSnapshotProvider.emergencyFund / cash` | `netWorthSnapshotProvider` (manter) + `snapshot.totalSpent` ⚠️ |

Os dois últimos (habitação e fundo de emergência) ainda precisam de dados não expostos diretamente no snapshot. Estratégia: manter apenas esses dois providers e remover os outros 3.

#### O que muda

```dart
// ❌ ANTES — 5 providers + cálculo manual
final net = ref.watch(effectiveNetSalaryProvider);
final cash = ref.watch(cashExpensesProvider);
final byCategory = ref.watch(cashExpensesByCategoryProvider);
final balance = ref.watch(cashRemainingProvider);
final inst = ref.watch(installmentsProvider).value ?? [];
final instTotal = inst.fold(0.0, (s, i) => s + i.monthlyAmount);
final score = FinancialCalculatorService.calculateHealthScore(...);
final savingsRate = net > 0 ? (net - cash) / net * 100 : 0.0;
final installmentsRate = net > 0 ? instTotal / net * 100 : 0.0;

// ✅ DEPOIS — 3 providers, score e rates do snapshot
final snap = ref.watch(financialSnapshotProvider);          // novo
final byCategory = ref.watch(cashExpensesByCategoryProvider); // mantém (housing)
final nwSnap = ref.watch(netWorthSnapshotProvider).value;   // mantém (ef)

final score = snap.healthScore;
final savingsRate = snap.savingsRate * 100;
final balance = snap.currentBalance.amount;
final net = snap.cashIncome.amount;
final installmentsRate = net > 0
    ? snap.totalFutureObligations.amount / net * 100
    : 0.0;
// housing e efMonths: mantém cálculo atual com byCategory e nwSnap
```

**Providers removidos desta tela**:
- `cashExpensesProvider`
- `cashRemainingProvider`
- `installmentsProvider` (CardInstallment — o mais importante de remover)

**Arquivos modificados**:
- `lib/features/health/health_screen.dart`

**Teste de sucesso**: Health screen mostra mesmo score que o `HealthGaugeCard` no dashboard (ambos usam `snapshot.healthScore`). Sub-scores batem com os valores do período corrente.

---

### FASE 4 — transactions_screen: aposentar deleteFixedSeriesFrom
**Objetivo**: Remover o padrão `isFixed + deleteFixedSeriesFrom` da UI de transações.
**Reversibilidade**: Média — requer verificação de dados em produção antes.
**Pré-condição**: Verificar quantos expenses ainda têm `is_fixed=true` e `recurring_rule_id IS NULL` em produção.

#### Verificação de dados (executar no Supabase SQL editor antes de implementar)

```sql
-- Quantos expenses legados isFixed ainda existem sem RecurringRule associada?
SELECT COUNT(*) as legacy_fixed_count
FROM expenses
WHERE is_fixed = true
  AND recurring_rule_id IS NULL
  AND user_id = auth.uid();
```

#### Cenário A: `legacy_fixed_count = 0` (migração completa)

Remover a branch `isFixed` completamente:

```dart
// REMOVER este bloco inteiro:
if (isFixed) {
  final choice = await showDeleteExpenseChoiceDialog(...)
  ...
  await ref.read(expenseRepositoryProvider).deleteFixedSeriesFrom(expense);
}
```

E deprecar `deleteFixedSeriesFrom` no repositório (manter por 1 release, depois remover).

#### Cenário B: `legacy_fixed_count > 0` (ainda há expenses legados)

Substituir o comportamento: em vez de "Excluir toda a série", mostrar aviso ao usuário para converter em RecurringRule:

```dart
// ✅ DEPOIS — cenário B
if (isFixed && expense.recurringRuleId == null) {
  // Expense legado — oferecer conversão
  await showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('Gasto fixo legado'),
    content: const Text('Este gasto foi criado como fixo. '
        'Para gerenciar a série completa, converta em Recorrente.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Só este mês')),
    ],
  ));
  return true; // deleta apenas este
}
```

**Arquivos modificados**:
- `lib/features/transactions/transactions_screen.dart`
- `lib/core/repositories/expense_repository.dart` (deprecar `deleteFixedSeriesFrom`)

**Teste de sucesso**: Swipe de delete em gasto `isFixed` sem `recurringRuleId` → mostra aviso de legacy. Gasto normal → dialog de confirmação padrão.

---

## ✅ Checklist de Completitude

### Fase 1 — Category Pickers ✅ 2026-05-08
- [x] `quick_add_bottom_sheet.dart`: `categoriesStreamProvider` → `categoriesRefProvider`
- [x] `quick_add_bottom_sheet.dart`: `_catChip` recebe `CategoryRef`
- [x] `quick_add_bottom_sheet.dart`: `_save` usa `CategoryRef.uncategorized()` como fallback
- [x] `edit_expense_bottom_sheet.dart`: `categoriesStreamProvider` → `categoriesRefProvider`
- [x] `edit_expense_bottom_sheet.dart`: chaves `_subcategories` convertidas para lowercase (bug fix: lookup nunca encontrava com UPPERCASE)
- [ ] Teste manual: criar gasto com categoria custom → aparece corretamente

### Fase 2 — expense_breakdown ✅ 2026-05-08
- [x] `expense_breakdown.dart`: `categoriesMapProvider` → `categoriesRefProvider` (mapa inline)
- [ ] Verificar em produção: categorias custom exibem nome e emoji corretos
- [ ] Sem regressão: categorias do sistema (housing, transport...) continuam exibindo

### Fase 3 — health_screen ✅ 2026-05-08
- [x] `health_screen.dart`: `financialSnap.healthScore` em vez de `calculateHealthScore()`
- [x] `financialSnap.savingsRate * 100` e `financialSnap.currentBalance.amount` para sub-scores
- [x] `installmentsProvider` (CardInstallment legado) removido da tela
- [x] `cashExpensesProvider` e `cashRemainingProvider` removidos
- [x] `byCategory['HOUSING']` corrigido para `byCategory['housing']`
- [ ] Verificar em produção: score idêntico ao `HealthGaugeCard` do dashboard

### Fase 4 — isFixed cleanup ✅ 2026-05-08 (Cenário B)
- [ ] Query SQL no Supabase ainda pendente (para decidir se migrar para Cenário A)
- [x] Branch `isFixed`: Cenário B aplicado — dialog de aviso, exclusão individual apenas
- [x] `deleteFixedSeriesFrom` marcado como `@Deprecated` no repositório
- [ ] Teste manual: swipe em gasto legacy isFixed → dialog de aviso exibido

---

## 🚨 Riscos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| `categoriesRefProvider` retorna lista vazia momentaneamente | Baixa | Já tem fallback `CategoryRef.uncategorized()` |
| `installmentsRate` via `totalFutureObligations` inclui recorrentes (não só parcelas) | Média | Documentar diferença; considerar exposição de `activeInstallmentsTotal` separado no snapshot |
| expenses com `is_fixed=true` em produção sem RecurringRule → delete silencioso | Alta se Cenário B | Verificar SQL antes de implementar Fase 4 |

---

## 📎 Referências

- Auditoria: `docs/architecture/ui_audit_2026_05_08.md`
- Bug já corrigido: `intelligence_layer.dart` (..take cascade)
- Providers destino: `lib/core/providers/providers.dart` → `categoriesRefProvider`, `financialSnapshotProvider`
- ADR de categorias: `docs/decisions/001-category-unification.md`
