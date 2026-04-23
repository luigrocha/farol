-- V2: Financial data tables (Supabase)
-- All user financial data is stored here for cross-device sync.
-- Local SQLite (Drift) is used only for device-specific settings (isFirstLaunch, etc.)

-- ==========================================
-- TABLE: incomes
-- ==========================================
create table if not exists incomes (
  id            bigserial primary key,
  user_id       uuid references auth.users(id) on delete cascade not null,
  month         int not null,
  year          int not null,
  income_type   text not null,
  amount        decimal(12,2) not null,
  is_net        boolean default true not null,
  inss_deducted decimal(12,2),
  irrf_deducted decimal(12,2),
  notes         text,
  created_at    timestamp with time zone default now() not null
);

alter table incomes enable row level security;
create policy "Users manage own incomes" on incomes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table incomes replica identity full;
alter publication supabase_realtime add table incomes;

-- ==========================================
-- TABLE: expenses
-- ==========================================
create table if not exists expenses (
  id                bigserial primary key,
  user_id           uuid references auth.users(id) on delete cascade not null,
  month             int not null,
  year              int not null,
  pay_type          text not null,
  category          text not null,
  subcategory       text,
  amount            decimal(12,2) not null,
  payment_method    text not null,
  installments      int default 1 not null,
  is_fixed          boolean default false not null,
  store_description text,
  created_at        timestamp with time zone default now() not null
);

alter table expenses enable row level security;
create policy "Users manage own expenses" on expenses
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table expenses replica identity full;
alter publication supabase_realtime add table expenses;

-- ==========================================
-- TABLE: card_installments
-- ==========================================
create table if not exists card_installments (
  id                  bigserial primary key,
  user_id             uuid references auth.users(id) on delete cascade not null,
  description         text not null,
  purchase_date       timestamp with time zone not null,
  total_value         decimal(12,2) not null,
  num_installments    int not null,
  current_installment int not null,
  monthly_amount      decimal(12,2) not null,
  status              text default 'Active' not null,
  notes               text,
  created_at          timestamp with time zone default now() not null
);

alter table card_installments enable row level security;
create policy "Users manage own installments" on card_installments
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table card_installments replica identity full;
alter publication supabase_realtime add table card_installments;

-- ==========================================
-- TABLE: investments
-- ==========================================
create table if not exists investments (
  id              bigserial primary key,
  user_id         uuid references auth.users(id) on delete cascade not null,
  type            text not null,
  product_name    text not null,
  institution     text not null,
  date_added      timestamp with time zone not null,
  total_invested  decimal(12,2) not null,
  current_balance decimal(12,2) not null,
  return_amount   decimal(12,2) default 0 not null,
  liquidity       text,
  notes           text,
  created_at      timestamp with time zone default now() not null
);

alter table investments enable row level security;
create policy "Users manage own investments" on investments
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table investments replica identity full;
alter publication supabase_realtime add table investments;

-- ==========================================
-- TABLE: net_worth_snapshots
-- ==========================================
create table if not exists net_worth_snapshots (
  id                    bigserial primary key,
  user_id               uuid references auth.users(id) on delete cascade not null,
  month                 int not null,
  year                  int not null,
  fgts_balance          decimal(12,2) default 0 not null,
  investments_total     decimal(12,2) default 0 not null,
  emergency_fund        decimal(12,2) default 0 not null,
  pending_installments  decimal(12,2) default 0 not null,
  notes                 text,
  created_at            timestamp with time zone default now() not null,
  unique (user_id, month, year)
);

alter table net_worth_snapshots enable row level security;
create policy "Users manage own snapshots" on net_worth_snapshots
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table net_worth_snapshots replica identity full;
alter publication supabase_realtime add table net_worth_snapshots;

-- ==========================================
-- TABLE: budget_goals
-- ==========================================
create table if not exists budget_goals (
  id                bigserial primary key,
  user_id           uuid references auth.users(id) on delete cascade not null,
  category          text not null,
  target_percentage decimal(5,2) not null,
  target_amount     decimal(12,2) not null,
  type              text not null,
  created_at        timestamp with time zone default now() not null
);

alter table budget_goals enable row level security;
create policy "Users manage own budget goals" on budget_goals
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table budget_goals replica identity full;
alter publication supabase_realtime add table budget_goals;
