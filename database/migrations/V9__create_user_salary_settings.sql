-- V9: CLT salary settings with auto-calculated payroll deductions (competência 2026)
-- One row per user; upserted from the Flutter app whenever gross salary changes.

create table if not exists user_salary_settings (
  id                     uuid primary key default gen_random_uuid(),
  user_id                uuid references auth.users(id) on delete cascade not null,

  -- Input
  salario_bruto          numeric(12, 2) not null default 0,
  dependentes            int           not null default 0,
  outras_deducoes        numeric(12, 2) not null default 0,
  desconto_simplificado  boolean       not null default false,

  -- Calculated (persisted for history / reporting)
  inss                   numeric(12, 2) not null default 0,
  irrf                   numeric(12, 2) not null default 0,
  salario_liquido        numeric(12, 2) not null default 0,
  fgts                   numeric(12, 2) not null default 0,

  created_at             timestamp with time zone not null default now(),
  updated_at             timestamp with time zone not null default now(),

  constraint user_salary_settings_user_id_unique unique (user_id)
);

-- Index for fast single-user lookups
create index if not exists idx_user_salary_settings_user_id
  on user_salary_settings (user_id);

-- RLS: users can only read/write their own row
alter table user_salary_settings enable row level security;

create policy "Users manage own salary settings"
  on user_salary_settings
  for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Auto-update updated_at on every write
create or replace function set_updated_at()
  returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_user_salary_settings_updated_at
  before update on user_salary_settings
  for each row execute procedure set_updated_at();
