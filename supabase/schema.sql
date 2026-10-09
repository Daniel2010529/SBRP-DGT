-- SBRP DGT Portal - esquema base. Revisa antes de ejecutar en un proyecto existente.
create extension if not exists pgcrypto;
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade,full_name text,role text not null default 'citizen' check(role in('citizen','staff','police','instructor','admin')),created_at timestamptz not null default now());
create table if not exists public.licenses(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,license_type text not null,status text not null default 'pending',issued_at date,expires_at date,created_at timestamptz not null default now());
create table if not exists public.vehicles(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,plate text not null,make text not null,model text not null,year integer,status text not null default 'pending',created_at timestamptz not null default now());
create table if not exists public.fines(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,reference text,reason text not null,amount numeric(10,2) not null default 0 check(amount>=0),points integer not null default 0 check(points>=0),status text not null default 'pending' check(status in('pending','paid','cancelled','under_review')),created_at timestamptz not null default now());
create table if not exists public.appointments(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,service text not null,date_time timestamptz not null,status text not null default 'pending' check(status in('pending','confirmed','cancelled','completed')),notes text,created_at timestamptz not null default now());
create table if not exists public.documents(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,file_name text not null,document_type text,storage_path text not null,created_at timestamptz not null default now());
create table if not exists public.notifications(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,title text not null,message text not null,read_at timestamptz,created_at timestamptz not null default now());
create table if not exists public.exam_questions(id uuid primary key default gen_random_uuid(),exam_type text not null default 'B',question text not null,options jsonb not null,correct_index integer not null,explanation text,active boolean not null default true,created_at timestamptz not null default now());
create table if not exists public.exams(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,exam_type text not null default 'B',score integer,passed boolean not null default false,answers jsonb,created_at timestamptz not null default now());

create or replace function public.is_staff() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role in('admin','staff','police','instructor')) $$;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin') $$;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,full_name,role) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),'citizen') on conflict(id) do nothing; return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.licenses enable row level security; alter table public.vehicles enable row level security; alter table public.fines enable row level security; alter table public.appointments enable row level security; alter table public.documents enable row level security; alter table public.notifications enable row level security; alter table public.exam_questions enable row level security; alter table public.exams enable row level security;

drop policy if exists profiles_select_own_or_staff on public.profiles;
create policy profiles_select_own_or_staff on public.profiles for select to authenticated using(id=auth.uid() or public.is_staff());
drop policy if exists profiles_update_own_name on public.profiles;
create policy profiles_update_own_name on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles for update to authenticated using(public.is_admin()) with check(public.is_admin());
revoke update on public.profiles from authenticated;
grant update(full_name) on public.profiles to authenticated;
grant update(full_name,role) on public.profiles to authenticated;

-- Usuarios leen solo sus registros; personal autorizado puede leerlos para gestionar el servidor.
do $$ declare t text; begin foreach t in array array['licenses','vehicles','fines','appointments','documents','notifications','exams'] loop execute format('drop policy if exists %I on public.%I',t||'_select_owner_staff',t); execute format('create policy %I on public.%I for select to authenticated using(user_id=auth.uid() or public.is_staff())',t||'_select_owner_staff',t); end loop; end $$;
drop policy if exists vehicles_insert_own on public.vehicles;
create policy vehicles_insert_own on public.vehicles for insert to authenticated with check(user_id=auth.uid());
drop policy if exists vehicles_delete_pending_own on public.vehicles;
create policy vehicles_delete_pending_own on public.vehicles for delete to authenticated using(user_id=auth.uid() and status='pending');
drop policy if exists vehicles_staff_manage on public.vehicles;
create policy vehicles_staff_manage on public.vehicles for all to authenticated using(public.is_staff()) with check(public.is_staff());
drop policy if exists appointments_insert_own on public.appointments;
create policy appointments_insert_own on public.appointments for insert to authenticated with check(user_id=auth.uid());
drop policy if exists appointments_delete_pending_own on public.appointments;
create policy appointments_delete_pending_own on public.appointments for delete to authenticated using(user_id=auth.uid() and status='pending');
drop policy if exists appointments_staff_manage on public.appointments;
create policy appointments_staff_manage on public.appointments for all to authenticated using(public.is_staff()) with check(public.is_staff());
drop policy if exists documents_insert_own on public.documents;
create policy documents_insert_own on public.documents for insert to authenticated with check(user_id=auth.uid());
drop policy if exists documents_staff_manage on public.documents;
create policy documents_staff_manage on public.documents for all to authenticated using(public.is_staff()) with check(public.is_staff());
drop policy if exists notifications_staff_manage on public.notifications;
create policy notifications_staff_manage on public.notifications for all to authenticated using(public.is_staff()) with check(public.is_staff());
drop policy if exists fines_staff_manage on public.fines;
create policy fines_staff_manage on public.fines for all to authenticated using(public.is_staff()) with check(public.is_staff());
drop policy if exists licenses_staff_manage on public.licenses;
create policy licenses_staff_manage on public.licenses for all to authenticated using(public.is_staff()) with check(public.is_staff());
drop policy if exists exams_insert_own on public.exams;
create policy exams_insert_own on public.exams for insert to authenticated with check(user_id=auth.uid());
drop policy if exists exams_staff_manage on public.exams;
create policy exams_staff_manage on public.exams for all to authenticated using(public.is_staff()) with check(public.is_staff());
drop policy if exists questions_read_active on public.exam_questions;
create policy questions_read_active on public.exam_questions for select to authenticated using(active=true);
drop policy if exists questions_staff_manage on public.exam_questions;
create policy questions_staff_manage on public.exam_questions for all to authenticated using(public.is_staff()) with check(public.is_staff());

insert into storage.buckets(id,name,public) values('documents','documents',false) on conflict(id) do update set public=false;
drop policy if exists documents_storage_read on storage.objects;
create policy documents_storage_read on storage.objects for select to authenticated using(bucket_id='documents' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_staff()));
drop policy if exists documents_storage_insert on storage.objects;
create policy documents_storage_insert on storage.objects for insert to authenticated with check(bucket_id='documents' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists documents_storage_delete on storage.objects;
create policy documents_storage_delete on storage.objects for delete to authenticated using(bucket_id='documents' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_staff()));

-- Para exámenes evaluados, calcula la nota en servidor; no expongas correct_index al cliente.

-- Módulos extra SBRP v2: incidencias, comunicados y auditoría interna.
create table if not exists public.support_tickets(
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 reference text not null unique, category text not null default 'General', subject text not null,
 description text not null, status text not null default 'open' check(status in('open','in_progress','waiting_user','resolved','closed')),
 priority text not null default 'normal' check(priority in('low','normal','high','urgent')),
 assigned_to uuid references public.profiles(id) on delete set null, staff_reply text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.announcements(
 id uuid primary key default gen_random_uuid(), author_id uuid references public.profiles(id) on delete set null,
 title text not null, category text not null default 'General', body text not null,
 pinned boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.audit_events(
 id uuid primary key default gen_random_uuid(), actor_id uuid references public.profiles(id) on delete set null,
 action text not null, table_name text not null, record_id text, details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
alter table public.support_tickets enable row level security;
alter table public.announcements enable row level security;
alter table public.audit_events enable row level security;
drop policy if exists tickets_select_owner_staff on public.support_tickets;
create policy tickets_select_owner_staff on public.support_tickets for select to authenticated using(user_id=auth.uid() or public.is_staff());
drop policy if exists tickets_insert_owner on public.support_tickets;
create policy tickets_insert_owner on public.support_tickets for insert to authenticated with check(user_id=auth.uid());
drop policy if exists tickets_staff_update on public.support_tickets;
create policy tickets_staff_update on public.support_tickets for update to authenticated using(public.is_staff()) with check(public.is_staff());
drop policy if exists tickets_staff_delete on public.support_tickets;
create policy tickets_staff_delete on public.support_tickets for delete to authenticated using(public.is_staff());
drop policy if exists announcements_read_authenticated on public.announcements;
create policy announcements_read_authenticated on public.announcements for select to authenticated using(true);
drop policy if exists announcements_staff_manage on public.announcements;
create policy announcements_staff_manage on public.announcements for all to authenticated using(public.is_staff()) with check(public.is_staff());
drop policy if exists audit_staff_read on public.audit_events;
create policy audit_staff_read on public.audit_events for select to authenticated using(public.is_staff());

-- Impide que un usuario se conceda el rol admin editando su propio perfil.
create or replace function public.guard_profile_role_change() returns trigger language plpgsql set search_path=public as $$
begin
 if new.role is distinct from old.role and not public.is_admin() then
   raise exception 'Solo un administrador puede cambiar roles.' using errcode='42501';
 end if;
 return new;
end; $$;
drop trigger if exists guard_profile_role_change_trigger on public.profiles;
create trigger guard_profile_role_change_trigger before update of role on public.profiles for each row execute function public.guard_profile_role_change();

create or replace function public.audit_sbrp_change() returns trigger language plpgsql security definer set search_path=public as $$
declare rid text; act text; begin
 if tg_op='DELETE' then rid:=old.id::text; act:='delete';
 elsif tg_op='UPDATE' then rid:=new.id::text; act:='update';
 else rid:=new.id::text; act:='insert'; end if;
 insert into public.audit_events(actor_id,action,table_name,record_id,details)
 values(auth.uid(),act,tg_table_name,rid,jsonb_build_object('operation',tg_op,'timestamp',now()));
 if tg_op='DELETE' then return old; else return new; end if;
end; $$;
drop trigger if exists audit_vehicles on public.vehicles;
create trigger audit_vehicles after insert or update or delete on public.vehicles for each row execute function public.audit_sbrp_change();
drop trigger if exists audit_fines on public.fines;
create trigger audit_fines after insert or update or delete on public.fines for each row execute function public.audit_sbrp_change();
drop trigger if exists audit_appointments on public.appointments;
create trigger audit_appointments after insert or update or delete on public.appointments for each row execute function public.audit_sbrp_change();
drop trigger if exists audit_licenses on public.licenses;
create trigger audit_licenses after insert or update or delete on public.licenses for each row execute function public.audit_sbrp_change();
