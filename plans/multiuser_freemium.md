# Plan: Multiusuário (Workspace) + Freemium
**Área**: Arquitetura · DB · Auth · UI · Produto
**Prioridade**: P0 estratégico — define o modelo de negócio futuro
**Dependências**: Todas as migrações V1–V25 aplicadas ✅
**Status**: 🟡 Em planejamento

---

## 🎯 Posicionamento Estratégico

```
❌ ANTES: "controla tus gastos"
✅ AGORA: "entiende el futuro de tu dinero"
```

Farol não é um registrador de gastos. É um **copiloto financeiro preditivo**.
A diferença: um usuário que vê "se continuar assim, terminas o mês com -R$120"
muda de comportamento. Um usuário que só vê "gastaste R$800" não tem informação acionável.

---

## 📐 Modelo de Workspace

### Hierarquia

```
auth.users (Supabase Auth)
    └── workspace_members (N:M)
            └── workspaces
                    ├── expenses
                    ├── incomes
                    ├── installment_plans
                    ├── recurring_rules
                    ├── budget_goals
                    ├── period_budgets
                    ├── categories (custom)
                    ├── accounts
                    ├── investments
                    └── ...todos os dados financeiros
```

### Casos de uso reais

| Caso | Workspace | Membros | Permissões |
|---|---|---|---|
| Solo | Personal (auto-criado) | 1 | owner |
| Casal | "Nossa Casa" | 2 | owner + admin |
| Roommates | "Apt 42" | 3–5 | owner + members |
| Família | "Família Grocha" | N | owner + admins + viewers |
| Freelancer | "Pessoal" + "LTDA" | 1–2 | owner em ambos |

### Regra fundamental

> **Todo usuário novo ganha automaticamente um workspace pessoal.**
> A UX solo não muda em nada. O workspace é invisível até que o usuário convide alguém.

---

## 🗄️ Schema DB — Migrações

### V26 — Tabela `workspaces`

```sql
CREATE TABLE workspaces (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  slug          TEXT UNIQUE,
  owner_id      UUID NOT NULL REFERENCES auth.users(id),
  plan          TEXT NOT NULL DEFAULT 'free'
                CHECK (plan IN ('free', 'premium')),
  plan_expires_at TIMESTAMPTZ,                  -- NULL = free para sempre
  settings      JSONB DEFAULT '{}',             -- cutoffDay, currency, etc.
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Membros do workspace
CREATE TABLE workspace_members (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id  UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role          TEXT NOT NULL DEFAULT 'member'
                CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  invited_by    UUID REFERENCES auth.users(id),
  joined_at     TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (workspace_id, user_id)
);

-- Convites pendentes (email ainda não cadastrado)
CREATE TABLE workspace_invites (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id  UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  invited_email TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'member',
  token         TEXT NOT NULL UNIQUE DEFAULT gen_random_uuid()::text,
  invited_by    UUID NOT NULL REFERENCES auth.users(id),
  expires_at    TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days',
  accepted_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_invites ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "members can read workspace"
  ON workspaces FOR SELECT
  USING (id IN (
    SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "owner can update workspace"
  ON workspaces FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY "members can see members"
  ON workspace_members FOR SELECT
  USING (workspace_id IN (
    SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "admin+ can invite"
  ON workspace_invites FOR INSERT
  WITH CHECK (workspace_id IN (
    SELECT workspace_id FROM workspace_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  ));
```

### V27 — `workspace_id` em todas as tabelas de dados

```sql
-- Executar para cada tabela de dados:
-- expenses, incomes, investments, net_worth_snapshots,
-- accounts, account_transfers, budget_goals, period_budgets,
-- categories, salary_settings, installment_plans, installment_payments,
-- recurring_rules, recurring_occurrences

ALTER TABLE expenses        ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE incomes         ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE investments     ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE net_worth_snapshots ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE accounts        ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE account_transfers ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE budget_goals    ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE period_budgets  ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE categories      ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE salary_settings ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE installment_plans ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE installment_payments ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE recurring_rules ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
ALTER TABLE recurring_occurrences ADD COLUMN workspace_id UUID REFERENCES workspaces(id);
```

### V28 — Backfill: workspace pessoal para todos os usuários existentes

```sql
-- 1. Criar workspace pessoal para cada usuário
INSERT INTO workspaces (id, name, owner_id, plan)
SELECT
  gen_random_uuid(),
  COALESCE(raw_user_meta_data->>'full_name', email),
  id,
  'free'
FROM auth.users;

-- 2. Adicionar cada usuário como owner do seu workspace
INSERT INTO workspace_members (workspace_id, user_id, role)
SELECT w.id, w.owner_id, 'owner'
FROM workspaces w;

-- 3. Backfill workspace_id em todos os dados existentes
-- (repetir para cada tabela)
UPDATE expenses e
SET workspace_id = w.id
FROM workspaces w
WHERE w.owner_id = e.user_id AND e.workspace_id IS NULL;

-- (idem para incomes, investments, etc.)
```

### V29 — NOT NULL + índices

```sql
-- Após verificar que backfill está 100%:
ALTER TABLE expenses ALTER COLUMN workspace_id SET NOT NULL;
-- (idem para todas as tabelas)

-- Índices de performance
CREATE INDEX ON expenses (workspace_id, transaction_date DESC);
CREATE INDEX ON incomes (workspace_id, created_at DESC);
CREATE INDEX ON installment_plans (workspace_id);
CREATE INDEX ON recurring_rules (workspace_id);
```

### V30 — Atualizar RLS de todas as tabelas

```sql
-- Padrão para cada tabela: substituir "user_id = auth.uid()"
-- por "workspace_id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid())"

-- Exemplo para expenses:
DROP POLICY IF EXISTS "users can CRUD own expenses" ON expenses;

CREATE POLICY "workspace members can read expenses"
  ON expenses FOR SELECT
  USING (workspace_id IN (
    SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "workspace members can insert expenses"
  ON expenses FOR INSERT
  WITH CHECK (workspace_id IN (
    SELECT workspace_id FROM workspace_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'member')
  ));

CREATE POLICY "workspace members can update expenses"
  ON expenses FOR UPDATE
  USING (workspace_id IN (
    SELECT workspace_id FROM workspace_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'member')
  ));

CREATE POLICY "owner/admin can delete expenses"
  ON expenses FOR DELETE
  USING (workspace_id IN (
    SELECT workspace_id FROM workspace_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  ));

-- Repetir para todas as tabelas com o mesmo padrão.
```

---

## 🏗️ Arquitetura Flutter

### Novos modelos

```dart
// lib/core/models/workspace.dart
class Workspace {
  final String id;
  final String name;
  final String ownerId;
  final WorkspacePlan plan;            // free | premium
  final DateTime? planExpiresAt;
  final Map<String, dynamic> settings; // cutoffDay, currency, etc.
  final List<WorkspaceMember> members;
}

enum WorkspacePlan { free, premium }

class WorkspaceMember {
  final String userId;
  final String workspaceId;
  final WorkspaceRole role;
  final DateTime joinedAt;
}

enum WorkspaceRole { owner, admin, member, viewer }
```

### Novos providers

```dart
// lib/core/providers/workspace_providers.dart

/// Workspace ativo no momento (persiste em UserSettings Drift)
final activeWorkspaceProvider = StateNotifierProvider<WorkspaceNotifier, Workspace?>();

/// Todos os workspaces do usuário
final userWorkspacesProvider = StreamProvider<List<Workspace>>();

/// Plano do workspace ativo (para feature gating)
final workspacePlanProvider = Provider<WorkspacePlan>((ref) {
  return ref.watch(activeWorkspaceProvider)?.plan ?? WorkspacePlan.free;
});

/// Permissão do usuário no workspace ativo
final currentUserRoleProvider = Provider<WorkspaceRole>((ref) {
  final workspace = ref.watch(activeWorkspaceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  return workspace?.members
    .firstWhere((m) => m.userId == userId, orElse: () => ...)
    .role ?? WorkspaceRole.viewer;
});

/// Guard: retorna true se o usuário pode escrever
final canWriteProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role != WorkspaceRole.viewer;
});
```

### Repositories — mudança de assinatura

```dart
// Todos os repositories passam a aceitar workspaceId
// em vez de depender de auth.uid() implícito via RLS.
// O RLS ainda é a fonte de verdade de segurança —
// o workspaceId no query é apenas para clareza e índice.

class ExpenseRepository {
  Future<List<Expense>> getAll({required String workspaceId}) async {
    return await _supabase
      .from('expenses')
      .select()
      .eq('workspace_id', workspaceId)
      .order('transaction_date', ascending: false);
  }
}
```

### Feature gating — `FeatureGate` widget

```dart
// lib/core/widgets/feature_gate.dart

class FeatureGate extends ConsumerWidget {
  const FeatureGate({
    required this.feature,
    required this.child,
    this.fallback,
  });

  final PremiumFeature feature;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(workspacePlanProvider);
    final allowed = feature.isAllowed(plan);
    if (allowed) return child;
    return fallback ?? _UpgradePrompt(feature: feature);
  }
}

enum PremiumFeature {
  advancedForecasting,
  aiInsights,
  multiWorkspace,
  advancedAnalytics,
  cashflowProjections,
  exportPdf;

  bool isAllowed(WorkspacePlan plan) => switch (this) {
    // Tudo free por enquanto — descomentar conforme monetização
    _ => true,
    // advancedForecasting => plan == WorkspacePlan.premium,
    // aiInsights          => plan == WorkspacePlan.premium,
    // multiWorkspace      => plan == WorkspacePlan.premium,
  };
}
```

### Workspace switcher — UI

```dart
// Aparece no header/drawer quando o usuário tem >1 workspace
// No WorkspaceSwitcherSheet:
//   - Lista workspaces com badge de plano
//   - "Criar novo workspace" (premium gate)
//   - "Convidar membro" (owner/admin only)
```

---

## 🗺️ Estratégia de Implementação (fases)

### FASE 1 — Fundação invisível (sem breaking changes)
**Objetivo**: Infraestrutura criada, UX idêntica para usuários existentes.
**Risco**: Baixo — nada quebra, nenhuma feature removida.

```
1.1 — Executar V26: criar workspaces + workspace_members + workspace_invites
1.2 — Executar V27: adicionar workspace_id (nullable) a todas as tabelas
1.3 — Executar V28: backfill (workspace pessoal para cada usuário, linkar dados)
1.4 — Verificar: COUNT(*) WHERE workspace_id IS NULL = 0 em todas as tabelas
1.5 — Executar V29: NOT NULL + índices
1.6 — Executar V30: atualizar RLS (mais crítico — testar em staging)
1.7 — Flutter: criar Workspace model + WorkspaceMember + WorkspaceRole
1.8 — Flutter: criar workspaceRepositoryProvider
1.9 — Flutter: criar activeWorkspaceProvider (auto-seleciona único workspace)
1.10 — Flutter: passar workspaceId em todos os repository calls
```

✅ **Critério de aceite**: App funciona exatamente igual para usuário solo.
🧪 **Teste**: login → ver dados → criar expense → ver no dashboard. Nada mudou.

---

### FASE 2 — Workspace switcher + convites
**Objetivo**: Usuário pode criar e compartilhar workspaces.
**Risco**: Médio — nova UX, mas aditiva (não remove nada).

```
2.1 — Flutter: WorkspaceSwitcherSheet (drawer ou header tap)
2.2 — Flutter: CreateWorkspaceSheet (nome, emoji)
2.3 — Flutter: InviteMemberSheet (email + role selector)
2.4 — Supabase: Edge Function "send-invite-email" (link com token)
2.5 — Flutter: deep link handling para aceitar convite
2.6 — Flutter: MembersScreen (listar membros, mudar role, remover)
2.7 — Flutter: WorkspaceSettingsSheet (nome, cutoffDay por workspace)
2.8 — Flutter: badge de workspace no AppBar quando >1 workspace
```

✅ **Critério de aceite**: casal consegue criar workspace compartilhado,
ver as despesas um do outro em tempo real, e convidar via link.

---

### FASE 3 — Permissões + Feature gating
**Objetivo**: Controle fino de quem pode fazer o quê + infraestrutura freemium.
**Risco**: Baixo — é additive.

```
3.1 — Flutter: FeatureGate widget implementado (tudo free por padrão)
3.2 — Flutter: canWriteProvider — guard para viewers
3.3 — Flutter: desabilitar botões de edição para viewers
3.4 — Flutter: _UpgradePrompt placeholder (para quando monetizar)
3.5 — Flutter: PremiumFeature enum com todos os gates definidos
3.6 — Supabase: workspaces.plan field ativo (free/premium)
3.7 — Supabase: `check_premium_feature` helper function para RLS
```

✅ **Critério de aceite**: viewer consegue ver mas não editar.
Feature gates existem no código mas tudo permanece desbloqueado.

---

### FASE 4 — Monetização (futuro, quando decidir)
**Objetivo**: Ativar paywall para features premium.
**Risco**: Alto para retenção — fazer gradualmente.

```
4.1 — Integrar Stripe (RevenueCat recomendado para Flutter)
4.2 — Webhook Stripe → UPDATE workspaces SET plan = 'premium'
4.3 — Ligar PremiumFeature.isAllowed() às features escolhidas
4.4 — PaywallScreen com tabela de features free vs premium
4.5 — Pricing: R$X/mês ou R$Y/ano por workspace
4.6 — Período trial: 14 dias premium para novos workspaces
```

---

## 💸 Modelo Freemium Detalhado

### Free (para sempre)
| Feature | Notas |
|---|---|
| Tracking de gastos/receitas | Ilimitado |
| Orçamento por categoria | Ilimitado |
| Dashboard principal | Completo |
| Categorias custom | Ilimitado |
| Recorrentes | Ilimitado |
| Parcelamentos | Ilimitado |
| Sync offline | Completo |
| 1 workspace | Pessoal |

### Premium (quando ativar)
| Feature | Justificativa |
|---|---|
| Forecasting avançado (90 dias) | Diferenciador único — "copiloto" |
| IA Insights (IntelligenceLayer) | Alto valor percebido |
| Projeção de liquidez | Útil para planning avançado |
| Analytics avançados | Heavy users |
| Multi workspace | Famílias, freelancers |
| Export PDF | Declaração IR, contabilidade |
| Cashflow chart | Já implementado |

> **Decisão atual**: tudo FREE. Os gates existem no código
> mas `isAllowed()` retorna `true` para todos.
> Quando monetizar, basta descomentar as regras.

---

## ⚠️ Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Backfill incompleto (V28) | Média | Dados perdidos | Verificar COUNT IS NULL antes de V29 |
| RLS atualizado quebrando queries (V30) | Alta | App offline | Testar em staging com usuário real primeiro |
| Flutter repositories sem workspaceId | Alta | Crash / empty data | Rodar em ordem: DB → providers → repositories → UI |
| Conflito de dados em workspace compartilhado | Média | UX ruim | Usar `created_by UUID` nos registros para atribuição |
| Performance: subquery workspace_members no RLS | Média | Lentidão | Materializar view `user_workspaces` para queries frequentes |
| Usuário sem workspace (bug de onboarding) | Baixa | App quebrado | Trigger Supabase: `on auth.users INSERT → create personal workspace` |

---

## 🔧 Trigger de Onboarding (crítico)

```sql
-- Garante que todo usuário novo ganha workspace pessoal automaticamente.
-- Sem isso, um novo signup resulta em app vazio sem workspace.

CREATE OR REPLACE FUNCTION create_personal_workspace()
RETURNS TRIGGER AS $$
DECLARE
  new_workspace_id UUID;
BEGIN
  INSERT INTO workspaces (name, owner_id, plan)
  VALUES (
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.id,
    'free'
  )
  RETURNING id INTO new_workspace_id;

  INSERT INTO workspace_members (workspace_id, user_id, role)
  VALUES (new_workspace_id, NEW.id, 'owner');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_personal_workspace();
```

---

## 📊 Mudanças no CLAUDE.md

Após cada fase, atualizar:
- Status da fase (🔴 pendente → 🟡 em progresso → 🟢 completo)
- Migrações aplicadas (V26–V30)
- Providers adicionados

---

## ✅ Checklist por Fase

### Fase 1 — Fundação
- [ ] V26 aplicada (workspaces + workspace_members + invites)
- [ ] V27 aplicada (workspace_id nullable em 14 tabelas)
- [ ] V28 executada (backfill — todos os dados linkados)
- [ ] V28 verificada (COUNT IS NULL = 0 em todas as tabelas)
- [ ] V29 aplicada (NOT NULL + índices)
- [ ] V30 aplicada (RLS atualizado)
- [ ] Trigger `create_personal_workspace` ativo
- [ ] Workspace model Dart criado
- [ ] workspaceRepositoryProvider criado
- [ ] activeWorkspaceProvider criado
- [ ] Todos os repositories aceitam workspaceId
- [ ] App funciona igual para usuário solo

### Fase 2 — Workspace sharing
- [ ] WorkspaceSwitcherSheet
- [ ] CreateWorkspaceSheet
- [ ] InviteMemberSheet + email via Edge Function
- [ ] Deep link para aceitar convite
- [ ] MembersScreen
- [ ] WorkspaceSettingsSheet
- [ ] Badge no AppBar (multi-workspace)
- [ ] Teste: casal compartilhando workspace em tempo real

### Fase 3 — Permissões + Feature gating
- [ ] FeatureGate widget
- [ ] canWriteProvider
- [ ] Viewers não conseguem editar
- [ ] PremiumFeature enum (tudo free)
- [ ] _UpgradePrompt placeholder
- [ ] workspaces.plan ativo no Supabase

### Fase 4 — Monetização (quando decidir)
- [ ] RevenueCat integrado
- [ ] Webhook Stripe → plan update
- [ ] PaywallScreen
- [ ] Trial de 14 dias
- [ ] PremiumFeature.isAllowed() ativado para features escolhidas

---

## 📎 Referências

- Planos existentes: `plans/financial_engine.md`, `plans/offline_sync.md`
- ADR de decisões: `docs/decisions/`
- Stack: Flutter 3 / Dart 3 · Riverpod 2 · Drift · Supabase · Material 3
