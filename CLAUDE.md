# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Farol** is a Flutter personal finance app for Brazilian CLT workers. It manages salary, Swile benefits (meal/food vouchers), card installments, investments, net worth, and 13th salary calculations entirely offline using SQLite.

- **Status**: Active development
- **Architecture**: Cross-platform Flutter app (iOS, Android, macOS, Windows, Linux, Web)
- **Tech Stack**: Flutter 3, Dart 3, Riverpod 2, Drift (SQLite), Material 3, fl_chart
- **Language**: Portuguese (pt_BR) with i18n support

## Quick Start

### Prerequisites
- Flutter 3.x (https://flutter.dev)
- Dart SDK 3.0+ (included with Flutter)

### Essential Commands

```bash
# Install dependencies
flutter pub get

# Generate code (Drift DAOs, Riverpod observer)
dart run build_runner build --delete-conflicting-outputs

# Run on device/simulator (hot reload supported for UI changes)
flutter run -d chrome --web-renderer=html --dart-define-from-file=env.json

# Lint check (zero warnings/errors expected)
flutter analyze

# Run tests
flutter test

# Run a specific test file
flutter test test/smoke_test.dart
```

### Key Dev Notes
- **Hot Reload**: Works for UI changes only. Provider/database changes require full restart.
- **Build Runner**: Auto-triggers on `flutter pub get`; manually rebuild with `dart run build_runner build` after modifying Drift schema or annotations.
- **Database Migrations**: Drift handles auto-migrations on schema changes. For first setup, seed data loads from `lib/core/database/seed_data.dart`.

## Architecture

### Directory Structure

```
lib/
├── core/                          # Shared, domain-agnostic logic
│   ├── database/                  # Drift (SQLite)
│   │   ├── app_database.dart      # Schema + DAOs
│   │   ├── connection/            # Platform-specific DB connections
│   │   └── seed_data.dart         # Initial demo data
│   ├── i18n/                      # Internationalization (Portuguese + English)
│   │   └── app_localizations.dart # String keys + localization methods
│   ├── models/                    # Domain types, enums, constants
│   ├── providers/                 # 30+ Riverpod providers (auto-cached)
│   ├── repositories/              # Data access layer (wraps Drift DAOs)
│   ├── services/                  # Business logic (FinancialCalculatorService, ExportService)
│   ├── theme/                     # Material 3 theme + color palette
│   └── widgets/                   # Shared UI components
├── design/                        # Design system (tokens, design-specific widgets)
│   ├── farol_colors.dart          # Design tokens (colors, spacing, etc.)
│   ├── farol_theme.dart           # Material 3 theme definition
│   ├── farol_typography.dart      # Typography (Manrope font)
│   └── widgets/                   # Design system components (FarolButton, FarolCard, etc.)
├── features/                      # Feature-specific screens and logic
│   ├── dashboard/
│   ├── transactions/
│   ├── analytics/
│   ├── investments/
│   ├── settings/
│   ├── budget/
│   ├── period_budget/
│   ├── installments/
│   ├── benefits/                  # Swile vouchers
│   ├── simulators/                # 13th salary, FGTS calculators
│   ├── notifications/             # Budget alerts
│   ├── auth/                      # Supabase authentication
│   ├── profile/
│   ├── health/                    # Health score calculation
│   ├── onboarding/
│   └── net_worth/
└── main.dart                      # App entry point + bottom nav routing
```

### Key Architectural Patterns

#### 1. **State Management (Riverpod)**
All providers use `Provider.autoDispose` for zero-allocation memory management:
- Derived state (budgets, alerts, totals) computed from base providers
- Auto cleanup when UI detaches from provider
- No manual listeners or widget rebuilds

Example pattern:
```dart
final budgetAlertsProvider = Provider.autoDispose<List<BudgetAlert>>((ref) {
  final goals = ref.watch(budgetGoalsMapProvider);
  final spending = ref.watch(cashExpensesByCategoryProvider);
  // Pure function: derived from two sources
  return goals.entries.where(...).map(...).toList();
});
```

#### 2. **Database (Drift)**
Type-safe DAOs auto-generated from schema:
- All queries are type-safe and composable
- Migrations happen automatically on schema changes
- DAOs accessed via repositories for clean separation

```dart
// From repository
final april = await db.expensesDao.getByMonth(DateTime(2025, 4));
final byCategory = groupBy(april, (e) => e.category);
```

#### 3. **Repository Pattern**
Each data source (Drift, Supabase) wrapped in a repository:
- `ExpenseRepository` → `expensesDao`
- `IncomeRepository` → `incomesDao`
- `BudgetGoalsRepository` → `budgetGoalsDao`
- Enables easy mocking for tests

#### 4. **Design System**
Material 3 with custom color palette and extensions:
- `design/` holds pure design tokens (no business logic)
- `core/theme/` holds app-specific theme + Material configuration
- All custom widgets in `design/widgets/` (FarolButton, FarolCard, FarolPill, BRLText)

### Core Services

#### FinancialCalculatorService
All money math lives here:
- `formatBRL(double)` → BRL currency formatting
- `calculateINSS(double)` → Progressive 2025 table (4 brackets, capped)
- `calculateIRRF(double)` → 5-bracket progressive 2025 tax
- `calculateHealthScore()` → 0-10 scoring algorithm
- `calculateSavingsRate()` → (Net - Expenses) / Net × 100%

#### ExportService
Data export in multiple formats:
- CSV: Monthly expenses or income
- JSON: Full database backup (all tables, all time)
- Uses `share_plus` for AirDrop, WhatsApp, email sharing

### Database Schema

Key tables (Drift):
- **incomes** → Gross/net salary, Swile benefits, bonus, 13th salary
- **expenses** → All transactions with category, payment method, fixed flag
- **card_installments** → Installment tracking (active/settled/suspended)
- **investments** → Treasury, CDB, REIT positions
- **budget_goals** → Target spending per category
- **net_worth_snapshots** → Monthly snapshots for trends
- **user_settings** → App config (theme, profile name, etc.)

See `lib/core/database/app_database.dart` for full schema.

## Development Guidelines

### Adding New Features
1. Create feature folder under `lib/features/`
2. Create Riverpod providers for derived state in `lib/core/providers/providers.dart`
3. Add repository methods if new data source needed
4. Use existing design system components from `design/widgets/`

### Modifying Database Schema
1. Edit `lib/core/database/app_database.dart` (schema definition)
2. Run `dart run build_runner build --delete-conflicting-outputs`
3. Drift auto-generates DAOs and migrations
4. Update repositories if needed

### Adding Strings/Localization
1. Add key to `lib/core/i18n/app_localizations.dart`
2. Provide translations for both Portuguese and English
3. Use `context.l10n.keyName` in widgets to access

### Styling & Theming
- Use `design/farol_colors.dart` for color tokens (not hardcoded hex)
- Use `design/farol_typography.dart` for text styles
- Extend Material 3 theme in `core/theme/` for app-specific customization
- All custom widgets in `design/widgets/` use tokens for consistency

### Testing
- Unit tests in `test/` directory
- Smoke test checks basic app launch and navigation
- Run with `flutter test` or single file with `flutter test test/widget_test.dart`
- Auth testing uses Supabase integration test pattern

## Important Business Rules

### Budget Alerts
- **Green** (0–74% of target): No alert
- **Yellow** (75–89%): Warning badge
- **Orange** (90–99%): Critical badge
- **Red** (≥100%): Limit exceeded (banner + icon)

Colors: `tertiaryColor` (green), `secondaryColor` (yellow), `#FF6B35` (orange), `errorColor` (red)

### Health Score (0-10)
- Savings ≥20% → +2pts | 10-19% → +1pt
- Housing ≤30% → +2pts | 31-40% → +1pt
- Positive monthly balance → +2pts
- Emergency fund ≥3 months expenses → +2pts
- Card installments ≤30% of net → +1pt

### Swile Separation
Swile Meal + Food vouchers are **separate from cash budget**. They don't count toward expense limits or alerts.

### Installments
Credit card purchases auto-create `card_installments` records. These track remaining months and status (active/settled/suspended).

### 13th Salary Calculation
Uses 2025 tax tables:
- **INSS**: 4 brackets (7.5%–14%), capped at R$ 951.62
- **IRRF**: 5 brackets (0%–27.5%) with standard deduction + dependent deduction (R$ 189.59 each)

See `FinancialCalculatorService` for implementation.

## Known Quirks & Constraints

- **Hot Reload Limitations**: UI changes hot reload fine, but provider/database changes need full app restart
- **Web Support**: Optimized for mobile; web layout is secondary
- **Cloud Sync**: No cross-device sync (local SQLite only)
- **Single User**: One profile per device
- **Currency**: BRL only (hardcoded for Brazilian workers)
- **Build Artifacts**: Git-ignored (build/, .dart_tool/, pubspec.lock)

## Performance Considerations

- **Provider Memory**: All providers auto-dispose to free memory when unused. Watch the dependency chain to avoid unnecessary rebuilds.
- **Database Queries**: Complex queries in DAOs; use repositories to batch/cache results.
- **Charts**: `fl_chart` can be expensive with large datasets. Limit to recent months.
- **Riverpod Caching**: `.autoDispose` means no cache if no listeners. If expensive computation, consider `.asDependency` pattern.

## Common Issues & Solutions

### Build Runner Conflicts
If `dart run build_runner build` fails with conflicts, use `--delete-conflicting-outputs`:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Database Lock
If SQLite database is locked (e.g., during migrations), restart the app. Drift handles concurrency, but hot reload may leave a stale connection.

### Missing Localized Strings
If `context.l10n` is null or throws, ensure `MaterialApp` is wrapped with `LocalizationScope` and `app_localizations.dart` has all keys.

### Hot Reload Not Working
Full app restart needed for:
- Provider definition changes
- Database schema changes
- Global state initialization changes

## References

- **Riverpod Docs**: https://riverpod.dev
- **Drift Docs**: https://drift.simonbinder.eu
- **Flutter Material 3**: https://m3.material.io
- **Dart Patterns**: https://dart.dev/language/patterns
- **Flutter Localizations**: https://flutter.dev/docs/development/accessibility-and-localization/internationalization

## Useful Files to Know

- **Theme Colors**: `lib/design/farol_colors.dart` (design tokens), `lib/core/theme/farol_colors.dart` (Material 3 config)
- **Providers**: `lib/core/providers/providers.dart` (all state management in one file)
- **Database Schema**: `lib/core/database/app_database.dart`
- **Financial Math**: `lib/core/services/financial_calculator_service.dart`
- **Navigation**: `lib/main.dart` (bottom nav routing + theme setup)
- **Localization**: `lib/core/i18n/app_localizations.dart` (string keys)
