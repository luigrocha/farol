-- V4: User profiles table
-- Stores display name and avatar for each authenticated user.
-- A trigger auto-creates the row on signup so it always exists.

create table if not exists profiles (
  id           uuid references auth.users(id) on delete cascade primary key,
  email        text,
  display_name text,
  photo_url    text,
  metadata     jsonb default '{}'::jsonb not null,
  created_at   timestamp with time zone default now() not null,
  updated_at   timestamp with time zone default now() not null
);

alter table profiles enable row level security;

create policy "Users can read own profile"
  on profiles for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Auto-create a profile row whenever a new user signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Backfill profile rows for users that already exist
insert into public.profiles (id, email)
select id, email from auth.users
on conflict (id) do nothing;
