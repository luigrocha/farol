# Layout & Responsive Refactor — Farol

> **Objetivo**: Establecer una arquitectura de layout profesional, consistente y escalable para toda la app.
> **Fecha de auditoría**: 2026-05-18
> **Estado**: En progreso

---

## 1. Auditoría Global

### 1.1 Arquitectura de Navegación (MainShell)

**Archivo**: `lib/main.dart` — clase `MainShell`

**Patrón actual**: `Stack` + `Offstage` para mantener pantallas vivas. Correcto conceptualmente, pero con problemas derivados.

**Problemas detectados**:
- `_buildMobileShell` usa `Scaffold > body: _buildScreenStack()` — el body es un `Stack` de `Offstage`. Las pantallas internas **también tienen sus propios Scaffolds**. Esto crea **doble Scaffold** (outer shell + inner screen), lo que en mobile produce `NavigationBar` del shell + `AppBar` del screen sin coordinación de `SafeArea`.
- El breakpoint de responsive está hardcoded a `600px` en `MainShell` pero las pantallas internas usan `800px`, `900px`, `1200px` — **inconsistencia de breakpoints**.
- `NavigationBar` en mobile (bottom nav M3) consume espacio del viewport. Las pantallas internas no saben si están dentro del shell, por lo que agregan `SizedBox(height: 80/100)` al final para no quedar tapadas por el FAB — **parche visual, no arquitectura**.
- Desktop shell no tiene `SafeArea` alrededor del `NavigationRail` — en macOS con notch/barra de menú puede sufrir overlap.

---

### 1.2 DashboardScreen

**Archivo**: `lib/features/dashboard/dashboard_screen.dart`

**Patrón actual**: `Scaffold > Column > [ConnectivityBanner, Expanded > CustomScrollView]`

**Problema crítico — ROOT CAUSE del espacio gris gigante**:
```dart
Scaffold(
  body: Column(children: [
    ConnectivityBanner(),          // height variable (0 o ~40px)
    Expanded(
      child: CustomScrollView(...) // ← correcto
    ),
  ]),
)
```
Este patrón es correcto **solo si** `ConnectivityBanner` tiene altura definida. Si el banner no renderiza nada (`SizedBox.shrink()`) hay un frame donde `Column` calcula alturas incorrectamente porque el `Expanded` inside `Column` inside `Scaffold.body` necesita constraints definidos. La transición genera el "gray flash".

**Problema adicional**: El outer `MainShell` tiene `Scaffold` con `NavigationBar`. El `DashboardScreen` tiene su propio `Scaffold`. **Scaffold anidado** — el inner Scaffold no ve el `MediaQuery` correcto con `viewPadding` del bottom nav.

**_MobileDashboardSliver**: `SliverChildListDelegate` con `SizedBox(height: 100)` al final — padding hardcodeado para evitar que el FAB tape el contenido. Debe ser `MediaQuery.of(context).padding.bottom + 80`.

**FAB positioning**: `floatingActionButton` está en el inner `Scaffold`, pero el outer `Scaffold` tiene `NavigationBar`. El FAB sube automáticamente para no quedar sobre el nav bar — correcto en teoría, pero si hay double-Scaffold esto puede duplicar el offset.

---

### 1.3 TransactionsScreen

**Archivo**: `lib/features/transactions/transactions_screen.dart`

**Problemas**:
1. **NestedScrollView + CustomScrollView anidado** en mobile: `NestedScrollView > TabBarView > CustomScrollView`. Este patrón tiene physics conflicts en Flutter — los slivers del inner scroll compiten con el outer scroll. El resultado es scroll inconsistente o que el contenido no ocupa bien el espacio disponible.
2. **Desktop**: `Scaffold > Row > [Expanded > CustomScrollView, Expanded > _IncomeTab]`. La `_IncomeTab` internamente usa `CustomScrollView`. Dos `CustomScrollView` en paralelo en un `Row` dentro de un `Scaffold` — cada uno necesita sus propias constraints. Correcto si `Expanded` les da constraints definidas — esto funciona.
3. `_buildExpensesPanel` retorna un `CustomScrollView` crudo (sin Scaffold) que se incrusta en el `TabBarView` en mobile. Correcto.
4. `_TotalMonthlyHero` y `_FilterChips` se ponen en `SliverToBoxAdapter > Column` — las constraints son correctas.

---

### 1.4 AnalyticsScreen

**Problemas**:
1. `SliverFillRemaining` para el loading state — hace que el skeleton ocupe el resto de pantalla después del AppBar. Cuando los datos cargan se reemplaza por `SliverToBoxAdapter` — correcto, pero el transition puede verse como "salto".
2. En desktop: `SliverToBoxAdapter > Padding > Row > [Expanded, Expanded]` — los `Expanded` dentro del `Row` dentro del `SliverToBoxAdapter` necesitan que el `Row` tenga constraints de ancho. La `SliverToBoxAdapter` le da width=screenWidth — OK. Pero height es `intrinsic` — las `Column` internas dentro de los `Expanded` son `crossAxisAlignment.stretch` sin height definida. Pueden generar layout issues con children que tengan height infinita.
3. `_RangePicker` retorna un `SliverToBoxAdapter` — sus children internos usan `Expanded` dentro de `Row` — OK.

---

### 1.5 PeriodBudgetScreen

**Patrón**: `Scaffold > CustomScrollView > SliverAppBar + SliverFillRemaining/SliverList`

**Relativamente limpio**. Problemas menores:
- `SliverFillRemaining` en empty state hace que el empty state ocupe `screenHeight - appBarHeight`. En desktop puede verse enorme.
- `contentMaxWidth: 860` hardcodeado en el sliver — correcto, pero debería venir de un token global.
- FAB padding al final hardcodeado como `SizedBox(height: 80)`.

---

### 1.6 InvestmentsScreen

**Patrón**: `Scaffold > CustomScrollView > SliverAppBar + SliverPadding > SliverList`

**Problemas**:
- No tiene layout responsive — mismo layout en mobile y desktop. Las cards se extienden a full width en desktop.
- `_ConsolidatedHero`, `_AllocationCard` etc. usan `double.infinity` en algunos containers dentro del SliverList — correcto dentro de sliver context.
- `_InvestmentsList` contiene `_ImpactBadge` que retorna `Expanded` — este widget solo puede ser usado dentro de `Row/Column`. Si se usa en un contexto incorrecto genera RenderFlex error.

---

### 1.7 SettingsScreen

**Problemas**:
1. `shrinkWrap: true` + `NeverScrollableScrollPhysics` en una `ListView` anidada dentro del `CustomScrollView` — patrón anti-performante. Cada item en el `shrinkWrap` ListView hace un full pass de layout. Debería ser `SliverList` dentro del CustomScrollView padre.
2. Múltiples secciones como `_Section`, `_SalarySection`, `_BudgetSection` tienen `Column` internas con `crossAxisAlignment.stretch` — las cards dentro se extienden a full width en desktop, sin max-width.

---

### 1.8 RecurringScreen & InstallmentsScreen

**Patrón**: `Scaffold > CustomScrollView > SliverAppBar + SliverPadding/SliverList`

**Problemas**:
- `SliverChildListDelegate` con una `Column` gigante como primer child que contiene todos los items (`rules.map((r) => _RuleTile(r)).toList()`). Esto construye **todos los items de una vez** — no hay lazy loading. Para listas cortas es OK, pero para listas largas es problemático.
- Desktop: `SliverToBoxAdapter > ConstrainedBox > Center > SliverList` — mezcla `SliverList` dentro de `SliverToBoxAdapter` que es un `BoxAdapter`. Esto **no funciona** — `SliverList` no puede vivir dentro de `SliverToBoxAdapter`. Necesita revisión.

---

### 1.9 SpaceDashboardScreen

**Patrón**: `Scaffold > CustomScrollView`

**Relativamente correcto**. Problemas:
- `ListView.separated` con `shrinkWrap: true` dentro de `SliverToBoxAdapter` — mismo anti-pattern que settings.
- Desktop layout: `SliverToBoxAdapter > Row > [Expanded, Expanded]` — los `Expanded` dentro de `Row` son `Column` con widgets que no tienen altura definida, puede generar overflow.

---

### 1.10 SafeArea Strategy

**Problemas detectados**:
- `MainShell` no aplica `SafeArea` a nivel de shell, dejándolo a cada screen.
- Las screens usan `SliverAppBar` con `automaticallyImplyLeading` que respeta el padding, pero el body del `CustomScrollView` puede no tener bottom padding correcto.
- Las bottom sheets usan `MediaQuery.of(context).viewInsets.bottom` manualmente — correcto para keyboard, pero inconsistente.
- Los FABs en inner Scaffolds dentro de MainShell (que tiene NavigationBar) tienen doble offset — el FAB sube por el nav bar del outer Scaffold **y** por el nav bar del inner.

---

## 2. Root Causes Identificados

| # | Root Cause | Impacto | Pantallas |
|---|-----------|---------|-----------|
| RC-1 | **Double Scaffold**: inner screens tienen `Scaffold` dentro del `Scaffold` del `MainShell` | MediaQuery incorrecto, SafeArea duplicada, FAB offset doble | Todas las main screens |
| RC-2 | **Breakpoints inconsistentes**: `MainShell=600`, screens=`800/900/1200` | Layout desktop activa en momento distinto al shell | Dashboard, Transactions, Analytics |
| RC-3 | **shrinkWrap anti-pattern**: `ListView(shrinkWrap: true)` dentro de `CustomScrollView` | Performance, layout passes costosos, scroll comportamiento raro | Settings, Space, Installments |
| RC-4 | **SliverList dentro de SliverToBoxAdapter**: en RecurringScreen y otros en desktop | Layout error silencioso, items no visibles | Recurring, Installments (desktop) |
| RC-5 | **Column+all-items-at-once**: `SliverChildListDelegate([Column(children: items)])` | Todos los items construidos simultáneamente, no lazy | Recurring, Installments, Space |
| RC-6 | **FAB bottom padding hardcodeado**: `SizedBox(height: 80/100)` fijo | Espacios incorrectos en pantallas sin FAB o en desktop | Dashboard, Transactions, Budget |
| RC-7 | **Sin max-width en desktop**: cards se estiran a full width | Giant empty spaces en pantallas anchas | Settings, Investments, Health |
| RC-8 | **SafeArea inconsistente**: cada screen maneja su propia SafeArea | Notch overlap, bottom inset incorrecto | Varias |

---

## 3. Arquitectura Responsiva Propuesta

### 3.1 Breakpoints Unificados (single source of truth)

```dart
// lib/design/layout/farol_breakpoints.dart
abstract final class FarolBreakpoints {
  static const double mobile  = 0;
  static const double tablet  = 600;    // MainShell switch rail/bottom-nav
  static const double desktop = 800;    // 2-column layouts
  static const double wide    = 1200;   // 3-column layouts
  
  static const double contentMaxWidth   = 1440; // max content width
  static const double contentNarrow     = 680;  // single-column centered
  static const double contentMedium     = 960;  // two-column
  static const double sidebarWidth      = 212;  // desktop nav rail
}
```

### 3.2 Componentes Reutilizables

#### `FarolPageScaffold`
Shell estándar para todas las main screens. Elimina la necesidad de `Scaffold` en cada screen. Sabe si está dentro de `MainShell` y aplica correctamente `MediaQuery`.

#### `FarolScrollPage`  
`CustomScrollView` pre-configurado con `SliverAppBar`, contenido y padding correcto para FAB.

#### `FarolResponsiveLayout`
`LayoutBuilder`-based widget que entrega el layout correcto según breakpoints unificados.

#### `FarolContentConstraint`
`ConstrainedBox` + `Center` con `maxWidth` de tokens, para centrar contenido en desktop.

#### `FarolBottomPadding`
Padding dinámico que respeta FAB + NavigationBar + SafeArea — reemplaza todos los `SizedBox(height: 80/100)`.

---

## 4. Plan de Implementación

### Phase 1 — Foundation (tokens + componentes base)
- [x] Crear `lib/design/layout/farol_breakpoints.dart`
- [x] Crear `lib/design/layout/farol_layout_widgets.dart` (FarolScrollPage, FarolResponsiveLayout, FarolContentConstraint, FarolBottomPadding)
- [x] Crear `lib/design/layout/farol_page_scaffold.dart` (FarolPageScaffold)
- [x] Exportar desde `lib/design/layout/layout.dart`

### Phase 2 — Fix RC-3: shrinkWrap anti-pattern
- [ ] `settings_screen.dart`: reemplazar `ListView(shrinkWrap, NeverScroll)` por `SliverChildListDelegate` en el CustomScrollView padre
- [ ] `space_dashboard_screen.dart`: reemplazar `ListView.separated(shrinkWrap)` por `SliverList`
- [ ] `installments_screen.dart`: reemplazar `ListView.separated(shrinkWrap)` en detail por `Column` o `SliverList`

### Phase 3 — Fix RC-4/5: SliverList dentro SliverToBoxAdapter + lazy building
- [ ] `recurring_screen.dart` desktop: extraer `SliverList` fuera del `SliverToBoxAdapter`
- [ ] `installments_screen.dart` desktop: mismo fix
- [ ] Convertir `SliverChildListDelegate([Column(children: items)])` por `SliverList(delegate: SliverChildBuilderDelegate)` donde la lista puede ser larga

### Phase 4 — Fix RC-6: FAB bottom padding
- [ ] Reemplazar todos los `SizedBox(height: 80)` / `SizedBox(height: 100)` del final de listas por `FarolBottomPadding`
- [ ] Auditar: `dashboard_screen.dart`, `transactions_screen.dart`, `period_budget_screen.dart`, `analytics_screen.dart`, `investments_screen.dart`, `recurring_screen.dart`, `installments_screen.dart`

### Phase 5 — Fix RC-7: Max width en desktop
- [ ] `settings_screen.dart`: wrap content en `FarolContentConstraint`
- [ ] `investments_screen.dart`: layout responsive 2-column en desktop
- [ ] `health_screen.dart`: `FarolContentConstraint` en SliverPadding
- [ ] `analytics_screen.dart`: verificar que el `maxWidth` del desktop grid esté usando breakpoints del token

### Phase 6 — Fix RC-1/8: SafeArea strategy
- [ ] Verificar que `MainShell` aplique `MediaQuery.removePadding` o que las inner screens no dupliquen SafeArea
- [ ] Auditar bottom sheets — usar `Padding(bottom: MediaQuery.viewInsetsOf(context).bottom)` consistently
- [ ] FAB offset en double-Scaffold — evaluar si mover FABs al shell o dejar en cada screen con `floatingActionButtonLocation` explícita

### Phase 7 — Fix RC-2: Breakpoints unificados
- [ ] Reemplazar todos los breakpoints hardcodeados por constantes de `FarolBreakpoints`
- [ ] `MainShell`: `600 → FarolBreakpoints.tablet`
- [ ] `DashboardScreen`: `800 → FarolBreakpoints.desktop`, `1200 → FarolBreakpoints.wide`
- [ ] `TransactionsScreen`: `900 → FarolBreakpoints.desktop`
- [ ] `AnalyticsScreen`: `800 → FarolBreakpoints.desktop`
- [ ] `PeriodBudgetScreen`: `800 → FarolBreakpoints.desktop`
- [ ] `InstallmentsScreen`: `800 → FarolBreakpoints.desktop`
- [ ] `RecurringScreen`: `800 → FarolBreakpoints.desktop`

---

## 5. Reglas de Arquitectura (para nuevas pantallas)

### Scroll
```
✅ CustomScrollView + Slivers → scroll principal de toda pantalla
✅ SliverList(delegate: SliverChildBuilderDelegate) → listas largas (lazy)
✅ SliverChildListDelegate → listas cortas conocidas (<20 items)
✅ SingleChildScrollView → contenido corto sin listas (forms, bottom sheets)
❌ ListView(shrinkWrap: true) dentro de CustomScrollView
❌ NestedScrollView + CustomScrollView interno (usa SliverAppBar directamente)
❌ SliverList dentro de SliverToBoxAdapter
❌ Column(children: items.map(...)) para listas potencialmente largas
```

### Layout
```
✅ LayoutBuilder → para layouts responsive
✅ FarolBreakpoints.* → para todos los breakpoints
✅ FarolContentConstraint → para max-width en desktop
✅ Expanded/Flexible dentro de Row/Column con constraints definidos
❌ IntrinsicHeight (performance) — usar CrossAxisAlignment o explicit heights
❌ height: double.infinity en containers sin constraints definidos
❌ MediaQuery.of(context).size directamente → usar MediaQuery.sizeOf(context)
```

### Scaffolds
```
✅ Screens dentro de MainShell: NO usar Scaffold propio (usar FarolScrollPage)
✅ Screens navegadas (push): SÍ pueden tener su propio Scaffold
✅ SafeArea en top solo si no hay AppBar/SliverAppBar
✅ Bottom padding: FarolBottomPadding en lugar de SizedBox(height: 80)
❌ Scaffold dentro de Scaffold dentro de MainShell
```

### FAB
```
✅ FAB dentro de la screen con heroTag único por screen
✅ floatingActionButtonLocation para posicionamiento correcto
✅ FarolBottomPadding al final del scroll para no quedar tapado
❌ Padding manual de 80/100px fijo
```

---

## 6. Componentes Creados

| Componente | Archivo | Propósito |
|-----------|---------|-----------|
| `FarolBreakpoints` | `lib/design/layout/farol_breakpoints.dart` | Single source of truth para breakpoints |
| `FarolScrollPage` | `lib/design/layout/farol_layout_widgets.dart` | CustomScrollView pre-configurado |
| `FarolResponsiveLayout` | `lib/design/layout/farol_layout_widgets.dart` | Builder responsive por breakpoints |
| `FarolContentConstraint` | `lib/design/layout/farol_layout_widgets.dart` | Max-width + centrado para desktop |
| `FarolBottomPadding` | `lib/design/layout/farol_layout_widgets.dart` | Padding dinámico FAB-aware |
| `FarolTwoColumnLayout` | `lib/design/layout/farol_layout_widgets.dart` | Layout 2 columnas estándar |
| `FarolThreeColumnLayout` | `lib/design/layout/farol_layout_widgets.dart` | Layout 3 columnas para wide |

---

## 7. Checklist de Verificación por Pantalla

| Pantalla | RC-1 | RC-2 | RC-3 | RC-4/5 | RC-6 | RC-7 | RC-8 |
|---------|------|------|------|--------|------|------|------|
| DashboardScreen | ⚠️ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ⚠️ |
| TransactionsScreen | ⚠️ | ⚠️ | ✅ | ✅ | ⚠️ | ⚠️ | ✅ |
| AnalyticsScreen | ⚠️ | ⚠️ | ✅ | ✅ | ⚠️ | ✅ | ✅ |
| PeriodBudgetScreen | ⚠️ | ⚠️ | ✅ | ✅ | ⚠️ | ⚠️ | ✅ |
| InvestmentsScreen | ⚠️ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ✅ |
| SettingsScreen | ⚠️ | ✅ | ❌ | ✅ | ⚠️ | ❌ | ✅ |
| RecurringScreen | ⚠️ | ⚠️ | ✅ | ❌ | ⚠️ | ⚠️ | ✅ |
| InstallmentsScreen | ⚠️ | ⚠️ | ❌ | ❌ | ⚠️ | ⚠️ | ✅ |
| SpaceDashboardScreen | ✅ | ⚠️ | ❌ | ✅ | ⚠️ | ⚠️ | ✅ |
| HealthScreen | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ✅ |

✅ = OK | ⚠️ = Riesgo menor / necesita atención | ❌ = Problema activo

---

## 8. Notas de Prioridad

**Alta prioridad** (causa el espacio gris gigante visible):
1. RC-6: `FarolBottomPadding` — reemplazar `SizedBox(height: 80/100)` hardcodeados
2. RC-7: `FarolContentConstraint` — evitar que cards se estiren en desktop
3. RC-3: eliminar `shrinkWrap` anti-patterns

**Media prioridad** (UX inconsistente pero no roto):
4. RC-2: unificar breakpoints con `FarolBreakpoints`
5. RC-4/5: lazy building en listas largas

**Baja prioridad** (refinamiento):
6. RC-1: evaluar si el double-Scaffold realmente causa problemas en producción antes de refactorizar
7. RC-8: SafeArea audit final
