# Farol 💰

A complete personal finance app for Brazilian CLT workers. Full control of salary, Swile benefits (Meal/Food vouchers), card installments, investments, net worth, and 13th salary simulation — all offline with SQLite and Riverpod reactive state management.

## ✨ Features

- **Dashboard** — Real-time net worth, savings rate, health score (0-10), and expense breakdown with 4-level budget alerts
- **Transactions** — Full expense/income/installment history with advanced filters and search
- **Analytics** — Revenue/expense trends, category distribution, savings evolution, and monthly charts
- **Investments** — Portfolio management with Treasury, CDB, and REIT positions; asset allocation insights
- **Budget Alerts** — 3-level proactive notifications:
  - 🟢 **Green** (0-74%) — Under control
  - 🟡 **Yellow** (75-89%) — Warning
  - 🟠 **Orange** (90-99%) — Critical
  - 🔴 **Red** (≥100%) — Limit exceeded
- **13th Salary Simulator** — INSS 2025 + IRRF 2025 with progressive tables, dependent deductions, and installment breakdown
- **Settings** — Profile management, budget goals by category, card installment tracking, theme toggle, and CSV/JSON export

## 📱 Screens

The app has 5 main screens accessible via bottom navigation, plus simulators in settings:

1. **Dashboard** - Net worth KPIs, health score, expense breakdown with alert colors, and top alert banner
2. **Transactions** - Expenses, income, and installments list with category filters and date range
3. **Analytics** - Trend charts, distribution, savings rate, and cash flow analysis
4. **Investments** - Portfolio overview, position tracking, and allocation suggestions
5. **Settings** - Profile data, goals, installments, simulators (13th salary), export, and theme

## 🏗 Architecture

```
lib/
├── core/
│   ├── database/
│   │   ├── app_database.dart              # Drift schema (SQLite) + DAOs
│   │   ├── app_database.g.dart            # Drift-generated code
│   │   └── seed_data.dart                 # Initial data (April 2025)
│   ├── models/
│   │   ├── enums.dart                     # Domain enums (ExpenseCategory, PaymentMethod, etc.)
│   │   ├── budget_alert.dart              # Budget alert model (AlertLevel enum)
│   │   └── constants.dart                 # Financial and UI constants
│   ├── providers/
│   │   └── providers.dart                 # 30+ Riverpod providers (derived state, caching)
│   ├── services/
│   │   ├── financial_calculator_service.dart  # Math: BRL formatting, tax calculations
│   │   └── export_service.dart                # CSV + JSON backup export
│   └── theme/
│       ├── app_theme.dart                 # Material 3 light/dark themes + constants
│       └── farol_colors.dart              # Color palette + theme extensions
├── features/
│   ├── dashboard/
│   │   └── dashboard_screen.dart          # KPIs, health score, expense breakdown, alerts
│   ├── transactions/
│   │   ├── transactions_screen.dart       # History with filters and search
│   │   └── quick_add_bottom_sheet.dart    # Fast expense entry
│   ├── analytics/
│   │   └── analytics_screen.dart          # Trend/distribution charts
│   ├── investments/
│   │   └── investments_screen.dart        # Portfolio and allocation
│   ├── notifications/
│   │   └── notifications_screen.dart      # Real-time budget alerts by level
│   ├── simulators/
│   │   └── thirteenth_salary_screen.dart  # INSS + IRRF calculator with tables
│   └── settings/
│       └── settings_screen.dart           # Profile, goals, installments, simulators, export
└── main.dart                              # Entry point + bottom nav shell
```

**State Management**: All data flows through Riverpod `Provider.autoDispose` for reactive, zero-allocation derived state (no manual listeners).

**Database**: Drift (SQLite) with DAOs for type-safe queries and automatic migrations. All data persists locally.

## 🛠 Tech Stack

| Layer | Technology | Package | Usage |
|---|---|---|---|
| **UI** | Flutter 3 Material 3 | `google_fonts`, `flutter_svg` | Custom Typography (Manrope), icons, theming |
| **State** | Riverpod 2 | `flutter_riverpod` | Reactive, auto-cached, zero-allocation providers |
| **Database** | SQLite | `drift` | Type-safe DAOs, auto migrations, seed data |
| **Charts** | Line/Pie/Bar | `fl_chart` | Dashboard trends, category distribution |
| **Export** | CSV + JSON | `csv`, `share_plus` | Monthly export, full backup, AirDrop/WhatsApp sharing |
| **Dev** | Code Generation | `build_runner` | Drift schema + DAOs, Riverpod observer |
| **Language** | Dart 3 | Typed records, destructuring patterns | Modern syntax for tax tables |

## 📊 Database Schema

| Table | Columns | Purpose |
|---|---|---|
| **incomes** | `id`, `amount`, `type`, `date` | Gross + net salary, Swile, bonus, 13th salary records |
| **expenses** | `id`, `amount`, `category`, `payment_method`, `date`, `is_fixed`, `memo` | Cash expenses, card spending, installments |
| **card_installments** | `id`, `description`, `total_amount`, `paid_amount`, `remaining_months`, `monthly_amount`, `status`, `created_at` | Credit card installment tracking (active/settled/suspended) |
| **investments** | `id`, `type`, `quantity`, `unit_price`, `created_at` | Treasury, CDB, REIT positions and cost basis |
| **net_worth_snapshots** | `id`, `month`, `fgts`, `cash_balance`, `investments_total` | Monthly snapshots for net worth trend |
| **budget_goals** | `id`, `category`, `target_amount`, `created_at` | Budget target per expense category |
| **user_settings** | `key`, `value` | App config (profile name, selected theme, etc.) |

## 📐 Business Rules

### Budget Alerts & Visualization

Budget targets are set in **Settings → Budget Goals** per category. Real-time alerts compare actual spending to targets:

| Level | Threshold | Color | Icon | Action |
|---|---|---|---|---|
| **Green** | 0–74% of target | `tertiaryColor` | — | No alert |
| **Yellow** | 75–89% of target | `secondaryColor` | ⚠️ | Warning badge |
| **Orange** | 90–99% of target | `#FF6B35` | ⚠️ | Critical badge |
| **Red** | ≥100% of target | `errorColor` | ❌ | Exceeded badge + banner |

Alerts appear in:
- **Dashboard** — Top banner, inline progress bars
- **Notifications Screen** — Full list grouped by severity

### Core Business Logic

1. **Swile separated**: Swile Meal + Food expenses do NOT count toward cash budget or alerts
2. **Auto installments**: Credit card purchase entry creates monthly `card_installments` record (active status)
3. **Savings Rate**: `(Net Salary - Cash Expenses) / Net Salary × 100%`
4. **Health Score** (0-10 scale):
   - Savings ≥20% → +2pts | 10-19% → +1pt
   - Housing ≤30% → +2pts | 31-40% → +1pt
   - Positive monthly balance → +2pts
   - Emergency fund ≥3 months expenses → +2pts
   - Card installments ≤30% of net salary → +1pt
5. **FGTS**: Auto-projected at 8% of gross (⚡ updates when salary changes)
6. **13th Salary Simulator** (in Settings):
   - **INSS 2025**: Progressive table (4 brackets, capped at R$ 951.62)
   - **IRRF 2025**: 5 brackets with standard deductions + dependent deduction (R$ 189.59 each)
   - Output: Both installments, total net, deductions breakdown

## 🚀 Setup

### Prerequisites
- **Flutter 3.x** (get it at flutter.dev)
- **Dart SDK ≥ 3.0** (comes with Flutter)
- **Git** for version control

### Installation

```bash
# Clone and navigate
git clone <repo>
cd farol

# Install dependencies
flutter pub get

# (First run only) Generate Drift DAOs + Riverpod observer
dart run build_runner build --delete-conflicting-outputs

# Run on device/simulator
flutter run

# Run on web (Chrome)
flutter run -d chrome --web-renderer=html
```

### First Launch

The app loads April 2025 demo data automatically. To reset and start fresh:
1. Delete the SQLite database file on your device (app data)
2. Restart the app

### Development

- **Flutter Analyze**: `flutter analyze` (zero errors/warnings)
- **Code Generation**: Auto-triggered on `flutter pub get`; manual rebuild: `dart run build_runner build`
- **Hot Reload**: Supported for UI changes; full restart needed for provider/database changes

### Initial Data

On first launch, the app automatically loads April 2025 demo data:

| Category | Amount | Notes |
|---|---|---|
| Gross Salary | R$ 13,287.90 | Monthly |
| Net Salary | R$ 9,651.91 | After INSS + IRRF |
| Swile Meal | R$ 1,400.00 | Monthly benefit |
| Swile Food | R$ 1,031.00 | Monthly benefit |
| Rent + Condo Fee | R$ 4,200.00 | Fixed housing expense |
| Fixed Expenses | R$ 2,150.00 | Utilities, insurance, subscriptions |
| FGTS Balance | R$ 19,888.00 | Fund for housing/emergencies |
| Active Card Installments | 1 | "Spouse Surgery" (2/12 @ R$ 754.97/mo) |
| Budget Goals (7 categories) | Configured | Grocery, Transport, Dining, etc. |

### 13th Salary Calculation Example

Using **R$ 7,000** gross monthly salary (12 months worked, 1 dependent):

#### Step 1: Calculate Base
```
Base = R$ 7,000 × 12 months ÷ 12 = R$ 7,000
```

#### Step 2: First Installment (June)
```
First Installment = R$ 7,000 ÷ 2 = R$ 3,500 ✅
(No deductions — pure gross)
```

#### Step 3: INSS Calculation (Progressive 2025)
```
Bracket 1: R$ 0 → R$ 1,518.00 @ 7.5%   = R$    113.85
Bracket 2: R$ 1,518.01 → R$ 2,793.88 @ 9%   = R$    114.83
Bracket 3: R$ 2,793.89 → R$ 4,190.83 @ 12%  = R$    167.63
Bracket 4: R$ 4,190.84 → R$ 7,000.00 @ 14%  = R$    393.28
                                        ———————————
Total INSS = R$ 789.59 (below R$ 951.62 cap)
```

#### Step 4: IRRF Calculation (Progressive 2025)
```
Taxable Base = R$ 7,000 - INSS (R$ 789.59) - Dependent (R$ 189.59) = R$ 6,020.82

Bracket 5 (> R$ 4,664.68): R$ 6,020.82 @ 27.5% - R$ 896.00
= (R$ 6,020.82 × 0.275) - R$ 896.00
= R$ 1,655.73 - R$ 896.00
= R$ 759.73
```

#### Step 5: Second Installment (December)
```
Second Installment = R$ 3,500 - INSS (R$ 789.59) - IRRF (R$ 759.73)
                   = R$ 1,950.68 💰
```

#### Summary
```
Gross 13th:        R$ 7,000.00
Deductions:      - R$ 1,549.32  (INSS: R$ 789.59 + IRRF: R$ 759.73)
                  ———————————
Net 13th:          R$ 5,450.68

First Installment (June):    R$ 3,500.00
Second Installment (Dec):    R$ 1,950.68
```

👉 **Try it yourself**: Go to **Settings → Simuladores → 13° Salário** to adjust the salary, months worked, and dependents in real-time.

## 🎨 Design & Theme

### Color Palette (Material 3)

| Role | Color | Hex | Usage |
|---|---|---|---|
| **Primary** | Dark Blue | `#1B3A5C` | Buttons, headers, key actions |
| **Secondary** | Green | `#1A7A4A` | Budget OK (75%), accent elements |
| **Tertiary** | Teal | `#0B7F7A` | Success state, healthy metrics |
| **Error** | Red | `#B91C1C` | Budget exceeded (≥100%) |
| **Critical** | Orange | `#FF6B35` | Budget critical (90-99%) |
| **Surface** | Light Gray | `#F3F4F6` | Cards, backgrounds |
| **On-Surface** | Dark Gray | `#1F2937` | Text on light backgrounds |

### Theme Support

- **Light Mode** — Default (high contrast, optimized for daytime)
- **Dark Mode** — OLED-friendly (high contrast, reduced eye strain)
- **System** — Follows device settings (toggle in Settings)

### Typography

- **Font**: [Manrope](https://fonts.google.com/specimen/Manrope) (geometric sans-serif)
- **Weights**: 400 (regular), 700 (bold), 800 (extra bold)
- **Sizes**: 12–30px (responsive across devices)

## 📤 Data Export & Backup

From **Settings → Exportar**:

| Format | Scope | Use Case |
|---|---|---|
| **CSV (Monthly)** | Expenses or income for 1 month | Share with accountant, import into spreadsheet |
| **JSON (Full)** | All tables, all time | Full backup, restore to new device, data migration |

Exports are shared via:
- **AirDrop** (iOS device to Mac)
- **WhatsApp** (share file to contact/group)
- **Email** (if configured)
- **Cloud storage** (if app has permissions)

⚠️ **JSON backups include sensitive data** (income, bank details). Encrypt backups or use secure storage.

## 🧪 Testing & Quality

- ✅ **Zero lint warnings**: `flutter analyze` passes completely
- ✅ **Material 3 spec compliance**: Navigation bar, cards, buttons, dialogs
- ✅ **Offline-first**: All features work without internet (SQLite is embedded)
- ✅ **Dark mode support**: Full contrast and readability verified
- ✅ **Responsive design**: Tested on phone (320–480dp) and tablet (600dp+)

## 🐛 Known Limitations

- **Web support**: Layout optimized for mobile; web experience is secondary
- **Cloud sync**: No cross-device sync (local SQLite only)
- **Multiple users**: Single-user app (one profile per device)
- **Currency**: Only BRL (R$) supported (hardcoded for Brazilian CLT workers)

## 📚 Architecture Highlights

### Riverpod State Management

All providers are `Provider.autoDispose` to minimize memory footprint:

```dart
// Example: Budget alerts derived from goals + spending
final budgetAlertsProvider = Provider.autoDispose<List<BudgetAlert>>((ref) {
  final goals = ref.watch(budgetGoalsMapProvider);
  final spending = ref.watch(cashExpensesByCategoryProvider);
  return goals.entries
    .where((g) => spending[g.key]! >= g.value.targetAmount * 0.75)
    .map((g) => BudgetAlert(...))
    .toList();
});
```

Zero side effects. Pure derived state. Automatic cleanup when listeners detach.

### Drift Database

Type-safe DAO pattern with auto-generated code:

```dart
// Queries are type-safe and composable
final april = await db.expensesDao.getByMonth(DateTime(2025, 4));
final byCategory = groupBy(april, (e) => e.category);
```

### Financial Calculations

All money math lives in `FinancialCalculatorService`:

```dart
static String formatBRL(double amount) => NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
).format(amount);

static double calculateINSS(double gross) { ... } // Progressive table
static double calculateIRRF(double taxableBase) { ... } // 5-bracket table
```

## 📄 License

Built for personal use. © 2025 Luis Rocha.

Powered by:
- **Flutter 3** + **Dart 3**
- **Riverpod 2** (reactive state)
- **Drift** (offline-first SQLite)
- **fl_chart** (beautiful charts)
- **Material 3** (Google Design System)
