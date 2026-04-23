-- V3: Add transaction_date to expenses for per-day grouping in the UI.
alter table expenses
  add column if not exists transaction_date date not null default current_date;
