-- V5: User Preferences
-- Stores per-user app preferences (locale, theme) so they sync across devices.

create table if not exists user_preferences (
  id         uuid default gen_random_uuid() primary key,
  user_id    uuid references auth.users(id) on delete cascade not null unique,
  locale     text not null default 'es',
  theme_mode text not null default 'system',
  updated_at timestamptz default now() not null
);

alter table user_preferences enable row level security;

create policy "Users manage own preferences"
  on user_preferences for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
