-- ═══════════════════════════════════════════
-- ACCOUNTS
-- ═══════════════════════════════════════════
create table if not exists public.accounts (
  id              bigserial primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  name            text not null,
  institution     text not null,
  type            text not null,  -- 'CHECKING' | 'SAVINGS' | 'INVESTMENT' | 'FGTS'
  current_balance numeric(14,2) not null default 0,
  is_active       boolean not null default true,
  notes           text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

alter table public.accounts enable row level security;

create policy "accounts: user owns rows"
  on public.accounts for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════
-- ACCOUNT TRANSFERS
-- ═══════════════════════════════════════════
create table if not exists public.account_transfers (
  id              bigserial primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  from_account_id bigint not null references public.accounts(id) on delete restrict,
  to_account_id   bigint not null references public.accounts(id) on delete restrict,
  amount          numeric(14,2) not null check (amount > 0),
  transfer_date   date not null,
  description     text,
  created_at      timestamptz not null default now()
);

alter table public.account_transfers enable row level security;

create policy "account_transfers: user owns rows"
  on public.account_transfers for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ═══════════════════════════════════════════
-- ATOMIC TRANSFER RPC
-- ═══════════════════════════════════════════
create or replace function public.execute_account_transfer(
  p_user_id       uuid,
  p_from_id       bigint,
  p_to_id         bigint,
  p_amount        numeric,
  p_date          date,
  p_description   text default null
) returns void
language plpgsql security definer as $$
begin
  if not exists (select 1 from public.accounts where id = p_from_id and user_id = p_user_id) then
    raise exception 'Unauthorized';
  end if;
  if not exists (select 1 from public.accounts where id = p_to_id and user_id = p_user_id) then
    raise exception 'Unauthorized';
  end if;

  update public.accounts
    set current_balance = current_balance - p_amount, updated_at = now()
    where id = p_from_id;

  update public.accounts
    set current_balance = current_balance + p_amount, updated_at = now()
    where id = p_to_id;

  insert into public.account_transfers(user_id, from_account_id, to_account_id, amount, transfer_date, description)
    values (p_user_id, p_from_id, p_to_id, p_amount, p_date, p_description);
end;
$$;

-- ═══════════════════════════════════════════
-- UPDATED_AT TRIGGER
-- ═══════════════════════════════════════════
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger accounts_updated_at
  before update on public.accounts
  for each row execute procedure public.set_updated_at();
