# Farol 💰

A complete personal finance app for Brazilian CLT workers.
Full control of salary, Swile benefits (Meal/Food vouchers), card installments,
investments, and net worth — all offline with SQLite.

## 📱 Screens

The app has 5 main screens accessible via bottom navigation:

1. **Dashboard** - Overview with KPIs, charts, and financial health score
2. **Transactions** - Expenses, income, and installments list with search and filters
3. **Analytics** - Trend charts, distribution, and savings evolution
4. **Investments** - Portfolio, allocation, and suggestions for conservative profile
5. **Settings** - Profile, goals, installments, export, and theme

## 🏗 Architecture

```
lib/
├── core/
│   ├── database/
│   │   ├── app_database.dart      # Drift schema (SQLite) + DAOs
│   │   ├── app_database.g.dart    # Drift-generated code
│   │   └── seed_data.dart         # Initial data (April 2025)
│   ├── models/
│   │   ├── enums.dart             # All domain enums
│   │   └── constants.dart         # Financial and UI constants
│   ├── providers/
│   │   └── providers.dart         # All Riverpod providers
│   ├── services/
│   │   ├── financial_calculator_service.dart  # Financial logic
│   │   └── export_service.dart               # CSV + JSON backup
│   └── theme/
│       └── app_theme.dart         # Material 3 light/dark themes
├── features/
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── transactions/
│   │   ├── transactions_screen.dart
│   │   └── quick_add_bottom_sheet.dart
│   ├── analytics/
│   │   └── analytics_screen.dart
│   ├── investments/
│   │   └── investments_screen.dart
│   └── settings/
│       └── settings_screen.dart
└── main.dart                      # Entry point + NavigationBar shell
```

## 🛠 Tech Stack

| Technology | Package | Usage |
|---|---|---|
| State Management | `flutter_riverpod` | Reactive providers |
| Database | `drift` (SQLite) | Offline-first with DAOs |
| Charts | `fl_chart` | Line, Pie, Bar charts |
| Export | `csv` + `share_plus` | CSV and JSON backup |
| UI | Material 3 | Custom color scheme |

## 📊 Database Tables

- **incomes** — Income records (salary, Swile, bonus, 13th salary)
- **expenses** — Expenses with category, payment method, fixed/variable
- **card_installments** — Card installments (active, settled, suspended)
- **investments** — Investment positions (Treasury, CDB, REITs, etc.)
- **net_worth_snapshots** — Monthly net worth snapshot (FGTS, investments)
- **budget_goals** — Budget goals by category (%)
- **user_settings** — User settings (key-value)

## 📐 Business Rules

1. **Swile separated**: Swile expenses do NOT count in the cash budget
2. **Auto installments**: When registering a credit installment, creates a record in `card_installments`
3. **Savings Rate**: `(Net Salary - Cash Expenses) / Net Salary × 100`
4. **Health Score** (0-10):
   - Savings ≥ 20% → +2pts | 10-19% → +1pt
   - Housing ≤ 30% → +2pts | 31-40% → +1pt
   - Positive balance → +2pts
   - Emergency fund ≥ 3 months → +2pts
   - Installments ≤ 30% → +1pt
5. **FGTS**: Automatic projection of 8% of gross salary (R$ 1,063/month)
6. **13th Salary**: Special prompt in Nov/Dec

## 🚀 Setup

### Prerequisites
- Flutter 3.x installed
- Dart SDK ≥ 3.0

### Installation

```bash
# Clone and enter the directory
cd farol

# Install dependencies
flutter pub get

# Generate Drift code (required on first run)
dart run build_runner build --delete-conflicting-outputs

# Run on simulator
flutter run

flutter run -d chrome --web-renderer=html --dart-define-from-file=env.json

```

make db-migrate` to run migrations

### Initial Data

On first launch, the app automatically loads April 2025 data:
- Net salary: R$ 9,651.91
- Swile Meal: R$ 1,400 + Food: R$ 1,031
- Pre-registered fixed expenses
- "Spouse Surgery" installment (2/12 - R$ 754.97/month)
- FGTS: R$ 19,888
- Configured budget goals

## 📋 Default User Data

| Field | Value |
|---|---|
| Gross Salary | R$ 13,287.90 |
| Net Salary | R$ 9,651.91 |
| Swile Meal | R$ 1,400.00 |
| Swile Food | R$ 1,031.00 |
| FGTS | R$ 19,888.00 |
| Rent + Condo Fee | R$ 4,200.00 |

## 🎨 Theme

| Color | Hex | Usage |
|---|---|---|
| Primary | `#1B3A5C` | Dark blue |
| Secondary | `#1A7A4A` | Green |
| Error | `#B91C1C` | Red |
| Warning | `#92400E` | Amber |
| Surface | `#F3F4F6` | Light gray |

Supports **Light**, **Dark**, and **System** themes.

## 📤 Export

- **CSV**: Exports expenses or income for the selected month
- **JSON**: Full backup with all data for restoration
- Sharing via `share_plus` (AirDrop, WhatsApp, etc.)

## 📄 License

Personal use. Built with Flutter + Drift + Riverpod.
