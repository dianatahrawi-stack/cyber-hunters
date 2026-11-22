-- CYBER HUNTERS database schema
-- Run this script in Supabase SQL Editor.
-- NOTE: This starter schema enables student participation only after a session
-- has been created by the instructor in the Supabase Table Editor.
-- Do not expose the service_role key in browser code.

create extension if not exists pgcrypto;

create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  title text not null default 'CYBER HUNTERS',
  status text not null default 'active' check (status in ('active','paused','closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  display_name text not null,
  team_name text not null,
  score integer not null default 0,
  mission_index integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.responses (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  player_id uuid not null references public.players(id) on delete cascade,
  mission_index integer not null,
  selected_option integer not null,
  is_correct boolean not null,
  points_earned integer not null default 0,
  created_at timestamptz not null default now(),
  unique(player_id, mission_index)
);

alter table public.sessions enable row level security;
alter table public.players enable row level security;
alter table public.responses enable row level security;

-- Public read access to active sessions is needed for students to join by code.
create policy "read active sessions" on public.sessions
for select to anon using (status = 'active');

-- Starter classroom policy: students can create player records and read
-- leaderboard rows. For a public event, add stronger abuse prevention and
-- instructor authentication before collecting real student identifiers.
create policy "join active session" on public.players
for insert to anon with check (
  exists (select 1 from public.sessions s where s.id = session_id and s.status = 'active')
);
create policy "read players for leaderboard" on public.players
for select to anon using (
  exists (select 1 from public.sessions s where s.id = session_id and s.status = 'active')
);
create policy "update own score starter" on public.players
for update to anon using (true) with check (score between 0 and 100 and mission_index between 0 and 5);

create policy "insert responses for active session" on public.responses
for insert to anon with check (
  exists (select 1 from public.sessions s where s.id = session_id and s.status = 'active')
);

alter publication supabase_realtime add table public.players;
