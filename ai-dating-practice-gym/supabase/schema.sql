-- AI Dating Practice Gym schema
-- Run this in Supabase SQL editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text,
  dating_goal text not null,
  tendencies jsonb not null default '[]'::jsonb,
  comfort_level int not null check (comfort_level between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.personas (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null,
  difficulty int not null check (difficulty between 1 and 5),
  system_prompt_template text not null,
  coaching_rubric jsonb not null default '{}'::jsonb,
  is_active boolean not null default true
);

create table if not exists public.settings (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  context_prompt_template text not null,
  is_active boolean not null default true
);

create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  persona_id uuid not null references public.personas(id),
  setting_id uuid not null references public.settings(id),
  status text not null default 'active' check (status in ('active', 'ended', 'coached')),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  overall_score int,
  summary text,
  meta jsonb not null default '{}'::jsonb
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  created_at timestamptz not null default now(),
  annotations jsonb not null default '{}'::jsonb
);

create table if not exists public.coaching_reports (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null unique references public.sessions(id) on delete cascade,
  overall_score int,
  payload jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  stripe_customer_id text,
  stripe_subscription_id text,
  status text,
  current_period_end timestamptz
);

create index if not exists idx_sessions_user_started on public.sessions(user_id, started_at desc);
create index if not exists idx_messages_session_created on public.messages(session_id, created_at asc);
create index if not exists idx_subscriptions_status on public.subscriptions(status);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.personas enable row level security;
alter table public.settings enable row level security;
alter table public.sessions enable row level security;
alter table public.messages enable row level security;
alter table public.coaching_reports enable row level security;
alter table public.subscriptions enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
using (auth.uid() = user_id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
with check (auth.uid() = user_id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "profiles_delete_own" on public.profiles;
create policy "profiles_delete_own"
on public.profiles
for delete
using (auth.uid() = user_id);

drop policy if exists "personas_read_authenticated" on public.personas;
create policy "personas_read_authenticated"
on public.personas
for select
using (auth.role() = 'authenticated');

drop policy if exists "settings_read_authenticated" on public.settings;
create policy "settings_read_authenticated"
on public.settings
for select
using (auth.role() = 'authenticated');

drop policy if exists "sessions_select_own" on public.sessions;
create policy "sessions_select_own"
on public.sessions
for select
using (auth.uid() = user_id);

drop policy if exists "sessions_insert_own" on public.sessions;
create policy "sessions_insert_own"
on public.sessions
for insert
with check (auth.uid() = user_id);

drop policy if exists "sessions_update_own" on public.sessions;
create policy "sessions_update_own"
on public.sessions
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "sessions_delete_own" on public.sessions;
create policy "sessions_delete_own"
on public.sessions
for delete
using (auth.uid() = user_id);

drop policy if exists "messages_select_own" on public.messages;
create policy "messages_select_own"
on public.messages
for select
using (
  exists (
    select 1
    from public.sessions s
    where s.id = messages.session_id and s.user_id = auth.uid()
  )
);

drop policy if exists "messages_insert_own" on public.messages;
create policy "messages_insert_own"
on public.messages
for insert
with check (
  exists (
    select 1
    from public.sessions s
    where s.id = messages.session_id and s.user_id = auth.uid()
  )
);

drop policy if exists "messages_update_own" on public.messages;
create policy "messages_update_own"
on public.messages
for update
using (
  exists (
    select 1
    from public.sessions s
    where s.id = messages.session_id and s.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.sessions s
    where s.id = messages.session_id and s.user_id = auth.uid()
  )
);

drop policy if exists "messages_delete_own" on public.messages;
create policy "messages_delete_own"
on public.messages
for delete
using (
  exists (
    select 1
    from public.sessions s
    where s.id = messages.session_id and s.user_id = auth.uid()
  )
);

drop policy if exists "coaching_reports_select_own" on public.coaching_reports;
create policy "coaching_reports_select_own"
on public.coaching_reports
for select
using (
  exists (
    select 1
    from public.sessions s
    where s.id = coaching_reports.session_id and s.user_id = auth.uid()
  )
);

drop policy if exists "coaching_reports_insert_own" on public.coaching_reports;
create policy "coaching_reports_insert_own"
on public.coaching_reports
for insert
with check (
  exists (
    select 1
    from public.sessions s
    where s.id = coaching_reports.session_id and s.user_id = auth.uid()
  )
);

drop policy if exists "coaching_reports_update_own" on public.coaching_reports;
create policy "coaching_reports_update_own"
on public.coaching_reports
for update
using (
  exists (
    select 1
    from public.sessions s
    where s.id = coaching_reports.session_id and s.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.sessions s
    where s.id = coaching_reports.session_id and s.user_id = auth.uid()
  )
);

drop policy if exists "coaching_reports_delete_own" on public.coaching_reports;
create policy "coaching_reports_delete_own"
on public.coaching_reports
for delete
using (
  exists (
    select 1
    from public.sessions s
    where s.id = coaching_reports.session_id and s.user_id = auth.uid()
  )
);

drop policy if exists "subscriptions_select_own" on public.subscriptions;
create policy "subscriptions_select_own"
on public.subscriptions
for select
using (auth.uid() = user_id);

drop policy if exists "subscriptions_insert_own" on public.subscriptions;
create policy "subscriptions_insert_own"
on public.subscriptions
for insert
with check (auth.uid() = user_id);

drop policy if exists "subscriptions_update_own" on public.subscriptions;
create policy "subscriptions_update_own"
on public.subscriptions
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "subscriptions_delete_own" on public.subscriptions;
create policy "subscriptions_delete_own"
on public.subscriptions
for delete
using (auth.uid() = user_id);
