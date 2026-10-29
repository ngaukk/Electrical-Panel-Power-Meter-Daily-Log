-- =============================================================================
-- Electrical Panel Power Meter Daily Log  |  Supabase database setup
-- Lam Soon Edible Oils Sdn. Bhd. (Telok Panglima Garang Factory)
--
-- Run once in Supabase: SQL Editor > New query > paste this whole file > Run.
-- Safe to run again: it only creates what is missing.
--
-- This file holds NO readings and NO staff emails, so it can sit in a public
-- GitHub repository. Add staff in Table Editor > staff (see README.md).
-- =============================================================================

-- 1. Tables -------------------------------------------------------------------
create table if not exists public.meters (
  id          text primary key,              -- LV1885, LV201357, SB-UT, COM, PUMP, SB-SM
  name        text not null,
  multiplier  numeric not null default 1,    -- CT/PT multiplier used for kWh usage
  sort_order  int not null
);

create table if not exists public.readings (
  id                 text primary key,       -- <meter>_<yyyy-mm-dd>, e.g. COM_2026-10-19
  meter              text not null references public.meters(id),
  reading_date       date not null,
  reading_time       text,                   -- HH:MM, set by the page when saved
  kwh                numeric not null check (kwh >= 0),   -- kWh register as shown on the meter
  max_demand_kw      numeric,
  power_factor       numeric check (power_factor between 0 and 1),
  remarks            text,
  recorded_by        text,
  recorded_by_email  text,
  source             text,                   -- 'import' for rows loaded from CSV
  updated_at         timestamptz not null default now(),
  unique (meter, reading_date)
);
create index if not exists readings_date_idx on public.readings (reading_date);

create table if not exists public.contacts (
  id          text primary key,
  sort_order  int,
  company     text,
  role        text,
  name        text,
  phone       text,
  email       text,
  note        text,
  updated_at  timestamptz not null default now()
);

create table if not exists public.staff (
  name   text primary key,                   -- shown in "Recorded by"
  email  text not null unique                -- the email they sign in with
);

-- 2. The six panel meters -------------------------------------------------------
insert into public.meters (id, name, multiplier, sort_order) values
  ('LV1885',   'Transformer 1', 1, 1),
  ('LV201357', 'Transformer 2', 1, 2),
  ('SB-UT',    'Utility',       1, 3),
  ('COM',      'Compressor',    1, 4),
  ('PUMP',     'Chiller Pump',  1, 5),
  ('SB-SM',    'Soap Main',     1, 6)
on conflict (id) do nothing;

-- 3. Security: only signed-in people listed in "staff" can read or change data ----
create or replace function public.is_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.staff s
                 where lower(s.email) = lower(coalesce(auth.jwt() ->> 'email', '')));
$$;
revoke execute on function public.is_staff() from public, anon;
grant  execute on function public.is_staff() to authenticated;

alter table public.meters   enable row level security;
alter table public.readings enable row level security;
alter table public.contacts enable row level security;
alter table public.staff    enable row level security;

drop policy if exists "staff read meters"  on public.meters;
drop policy if exists "staff edit meters"  on public.meters;
drop policy if exists "staff all readings" on public.readings;
drop policy if exists "staff all contacts" on public.contacts;
drop policy if exists "staff read staff"   on public.staff;

create policy "staff read meters"  on public.meters   for select to authenticated using (public.is_staff());
create policy "staff edit meters"  on public.meters   for update to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff all readings" on public.readings for all    to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff all contacts" on public.contacts for all    to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff read staff"   on public.staff    for select to authenticated using (public.is_staff());
-- Staff rows are added or removed only in the Supabase dashboard.

-- 4. Live updates: a reading saved on one phone appears on other open screens ------
do $$ begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'readings') then
      alter publication supabase_realtime add table public.readings; end if;
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'contacts') then
      alter publication supabase_realtime add table public.contacts; end if;
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'meters') then
      alter publication supabase_realtime add table public.meters; end if;
  end if;
end $$;

-- 5. Check ----------------------------------------------------------------------
select (select count(*) from public.meters)   as meters,     -- expect 6
       (select count(*) from public.readings) as readings,
       (select count(*) from public.staff)    as staff;
