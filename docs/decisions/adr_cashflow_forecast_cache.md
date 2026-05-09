# ADR: Cashflow Forecast Cache — Client-Side TTL vs. Supabase Edge Function

**Data:** 2026-05-08  
**Status:** Aceito  
**Contexto:** Task #23 — otimizar a performance da tela de analytics (cashflow chart 90 dias)

---

## Contexto

O `cashflowForecastProvider` faz 4 consultas async ao abrir a tela de analytics:
1. `pendingInstallmentPaymentsProvider` (Supabase)
2. `pendingRecurringOccurrencesProvider` (Supabase)
3. `expenseRepositoryProvider.getAll()` (Supabase — potencialmente centenas de registros)
4. `ForecastingEngine.buildProjection(buildForecastChart: true)` — simulação de 90 dias

Em dispositivos lentos ou conexões lentas, isso introduz delay visível toda vez que o usuário abre a tela de analytics.

---

## Decisão: Cache Client-Side com TTL (em vez de Supabase Edge Function)

### Opção rejeitada: Supabase Edge Function

**Por que foi cogitada:** Edge Function co-localizada com o banco executaria as queries sem latência de rede entre cliente e DB, e poderia servir resultado cacheado a múltiplos usuários.

**Por que foi rejeitada:**

1. **Dados pessoais, não compartilhados.** Cada usuário tem dados 100% diferentes. O cache server-side não tem benefício de compartilhamento — é basicamente um cache de sessão por usuário, igual ao client-side.

2. **Duplicata de lógica.** O `ForecastingEngine` é puro Dart com `Money` (centavos como int). Reescrever em TypeScript/Deno cria duas implementações que devem ser mantidas em sincronia. Alto risco de divergência.

3. **Não existe infraestrutura de Edge Functions no projeto.** Não há diretório `supabase/functions/`. Criar do zero inclui: setup de deploy pipeline, secrets, CORS, autenticação JWT, monitoring.

4. **Quebra o offline-first.** O app usa `SyncManager` + Drift para funcionar sem rede. Uma Edge Function necessitaria de fallback para computação local de qualquer forma — a Edge Function seria apenas uma otimização online que duplica código.

5. **Entidades de domínio sem serialização JSON.** `CashflowForecast`, `BurnRate`, `LiquidityRisk`, `ScheduledPayment` não tinham `toJson`/`fromJson`. Implementar para todas para consumir a resposta da Edge Function seria a mesma quantidade de trabalho — sem benefício extra.

### Opção escolhida: Cache Client-Side em Drift UserSettings

**Implementação:**
- `ForecastCacheRepository` persiste `CashflowForecast` serializado em `UserSettings['cashflow_forecast_cache']`
- Chave de cache inclui o período financeiro (`periodStart_periodEnd`) — period change = cache miss automático
- TTL: 2 horas (configurável em `ForecastCacheRepository._ttl`)
- `cashflowForecastProvider` verifica o cache primeiro; em cache hit, recomputa apenas `BurnRate`/`LiquidityRisk`/`projectedClosing` do snapshot live e anexa o chart cacheado

**Vantagens:**
- ✅ Funciona 100% offline (dados já no Drift)
- ✅ Zero nova infraestrutura
- ✅ Lógica de cálculo existe em um único lugar (Dart)
- ✅ Re-abertura da tela de analytics dentro de 2h: instantânea
- ✅ Mudança de período: cache miss automático

**Limitação conhecida:**
- Se o usuário adicionar transações e reabrir analytics dentro de 2h, o chart pode mostrar dados levemente desatualizados. Aceitável: o `InsightsPanel` e `BurnRateCard` no dashboard sempre usam dados ao vivo (não são cacheados).

---

## Adicionais implementados na mesma sessão

- `CashflowDataPoint.toJson`/`fromJson` e `CashflowForecast.toJson`/`fromJson` adicionados à entidade de domínio (valores puros, sem I/O — aceitável)
- `forecastCacheRepositoryProvider` em `providers.dart`
