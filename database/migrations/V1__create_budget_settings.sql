-- V1: Budget Settings
-- Stores per-user monthly income budgets in Supabase.
-- Local app tables (incomes, expenses, investments, etc.) are managed by
-- Drift (SQLite) on-device and are NOT part of these migrations.

create table if not exists budget_settings (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references auth.users(id) on delete cascade not null unique,
  net_salary  decimal(12,2) default 0 not null,
  swile_meal  decimal(12,2) default 0 not null,
  swile_food  decimal(12,2) default 0 not null,
  updated_at  timestamp with time zone default now() not null
);

alter table budget_settings enable row level security;

create policy "Users manage own budget"
  on budget_settings for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
