-- FamilienHub v3 – Supabase Backend
-- Im Supabase Dashboard unter SQL Editor einmal ausführen.
-- Danach in der App Project URL + Anon/Publishable Key eintragen.

create extension if not exists pgcrypto;

create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text unique not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  role text not null default 'member',
  created_at timestamptz not null default now(),
  primary key (family_id, user_id)
);

create table if not exists public.family_state (
  family_id uuid primary key references public.families(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.wish_reservations (
  family_id uuid not null references public.families(id) on delete cascade,
  wish_id text not null,
  reserved_by uuid not null references auth.users(id) on delete cascade,
  owner_user_id uuid null references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (family_id, wish_id)
);

alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.family_state enable row level security;
alter table public.wish_reservations enable row level security;

-- Hilfsfunktion: ist der aktuelle User Mitglied?
create or replace function public.is_family_member(fid uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists(
    select 1 from public.family_members m
    where m.family_id = fid and m.user_id = auth.uid()
  );
$$;

-- Familien lesen, wenn Mitglied.
drop policy if exists families_select_member on public.families;
create policy families_select_member on public.families
for select using (public.is_family_member(id));

-- Mitglieder dürfen Mitglieder derselben Familie sehen.
drop policy if exists members_select_member on public.family_members;
create policy members_select_member on public.family_members
for select using (public.is_family_member(family_id));

-- Eigene Mitgliedschaft darf aktualisiert werden.
drop policy if exists members_update_self on public.family_members;
create policy members_update_self on public.family_members
for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Gemeinsamen Familienzustand lesen/erstellen/ändern.
drop policy if exists state_select_member on public.family_state;
create policy state_select_member on public.family_state
for select using (public.is_family_member(family_id));

drop policy if exists state_insert_member on public.family_state;
create policy state_insert_member on public.family_state
for insert with check (public.is_family_member(family_id));

drop policy if exists state_update_member on public.family_state;
create policy state_update_member on public.family_state
for update using (public.is_family_member(family_id))
with check (public.is_family_member(family_id));

-- Reservierungen:
-- Mitglieder dürfen Reservierungen sehen, AUSSER wenn sie selbst Besitzer
-- des Wunsches sind. Für Kinder ohne eigenes Konto bleibt owner_user_id null.
drop policy if exists reservations_select_private on public.wish_reservations;
create policy reservations_select_private on public.wish_reservations
for select using (
  public.is_family_member(family_id)
  and (owner_user_id is null or owner_user_id <> auth.uid())
);

drop policy if exists reservations_insert_member on public.wish_reservations;
create policy reservations_insert_member on public.wish_reservations
for insert with check (
  public.is_family_member(family_id)
  and reserved_by = auth.uid()
  and (owner_user_id is null or owner_user_id <> auth.uid())
);

drop policy if exists reservations_delete_own on public.wish_reservations;
create policy reservations_delete_own on public.wish_reservations
for delete using (reserved_by = auth.uid());

-- Familie anlegen.
create or replace function public.create_family(p_name text, p_display_name text)
returns table(family_id uuid, family_name text, invite_code text)
language plpgsql security definer
set search_path = public
as $$
declare
  fid uuid;
  code text;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;

  loop
    code := upper(substr(encode(gen_random_bytes(8),'hex'),1,8));
    exit when not exists(select 1 from public.families where families.invite_code=code);
  end loop;

  insert into public.families(name, invite_code, created_by)
  values (p_name, code, auth.uid())
  returning id into fid;

  insert into public.family_members(family_id,user_id,display_name,role)
  values (fid,auth.uid(),p_display_name,'admin');

  insert into public.family_state(family_id,data)
  values (fid,'{}'::jsonb);

  return query select fid,p_name,code;
end;
$$;

-- Per Einladungscode beitreten.
create or replace function public.join_family(p_invite_code text, p_display_name text)
returns table(family_id uuid, family_name text, invite_code text)
language plpgsql security definer
set search_path = public
as $$
declare
  f public.families%rowtype;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;

  select * into f
  from public.families
  where upper(families.invite_code)=upper(p_invite_code);

  if f.id is null then raise exception 'Invalid invite code'; end if;

  insert into public.family_members(family_id,user_id,display_name,role)
  values (f.id,auth.uid(),p_display_name,'member')
  on conflict (family_id,user_id)
  do update set display_name=excluded.display_name;

  return query select f.id,f.name,f.invite_code;
end;
$$;

grant execute on function public.create_family(text,text) to authenticated;
grant execute on function public.join_family(text,text) to authenticated;
grant execute on function public.is_family_member(uuid) to authenticated;
