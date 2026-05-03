# CLAUDE.md

## Project
Farol = Flutter personal finance app (Brazil, CLT)
- Offline-first (SQLite via Drift)
- Handles salary, Swile, installments, investments, net worth, 13th salary
- Language: pt_BR (i18n enabled)

## Stack
- Flutter 3 / Dart 3
- Riverpod 2 (autoDispose)
- Drift (SQLite)
- Material 3
- fl_chart

## Architecture
- Feature-based (`lib/features/*`)
- Core shared logic in `lib/core/*`
- Design system in `lib/design/*`
- Repository pattern over DAOs
- Services for business logic

## Key Rules
- DO NOT refactor architecture unless explicitly requested
- Follow existing patterns (Riverpod + Repository + Drift)
- Prefer extending over rewriting
- Keep changes minimal and scoped

## State (Riverpod)
- All providers use `autoDispose`
- Derived state only (no side effects)
- Avoid unnecessary rebuild chains

## Database (Drift)
- Schema: `core/database/app_database.dart`
- Type-safe DAOs (generated)
- Run build_runner after schema changes
- Drift handles migrations

## Core Services
- FinancialCalculatorService → all money logic
- ExportService → CSV/JSON export

## Structure
- `core/` → database, providers, services
- `features/` → UI + feature logic
- `design/` → UI system (tokens + widgets)

## Dev Commands
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome --dart-define-from-file=env.json
flutter analyze
flutter test