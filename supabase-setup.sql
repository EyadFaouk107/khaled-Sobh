-- Run this whole file in Supabase Dashboard -> SQL Editor.
-- Then create a teacher account in Authentication -> Users and add its UUID to admin_users.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_site_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.admin_users where user_id = auth.uid()); $$;

create table if not exists public.content_items (
  id uuid primary key default gen_random_uuid(),
  content_type text not null check (content_type in ('sheet','revision')),
  stage_id text not null check (stage_id in ('prep1','prep2','prep3','sec1','sec2','sec3','unclassified')),
  title text not null check (char_length(title) between 1 and 180),
  unit text,
  year text,
  file_size text,
  pages text,
  file_url text,
  file_path text,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
alter table public.content_items enable row level security;

-- Admin can verify their own membership; only an existing admin can read the admin list.
drop policy if exists "Admins can read admin list" on public.admin_users;
create policy "Admins can read admin list" on public.admin_users for select to authenticated using (public.is_site_admin());

drop policy if exists "Public can read published content" on public.content_items;
create policy "Public can read published content" on public.content_items for select to anon, authenticated using (is_published = true or public.is_site_admin());
drop policy if exists "Admins can insert content" on public.content_items;
create policy "Admins can insert content" on public.content_items for insert to authenticated with check (public.is_site_admin());
drop policy if exists "Admins can update content" on public.content_items;
create policy "Admins can update content" on public.content_items for update to authenticated using (public.is_site_admin()) with check (public.is_site_admin());
drop policy if exists "Admins can delete content" on public.content_items;
create policy "Admins can delete content" on public.content_items for delete to authenticated using (public.is_site_admin());

grant select on public.content_items to anon, authenticated;
grant insert, update, delete on public.content_items to authenticated;
grant select on public.admin_users to authenticated;

-- Public bucket: PDFs can be viewed by site visitors; uploads/deletes are admin-only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('lesson-pdfs','lesson-pdfs',true,26214400,array['application/pdf'])
on conflict (id) do update set public=true, file_size_limit=26214400, allowed_mime_types=array['application/pdf'];

drop policy if exists "Public can read lesson PDFs" on storage.objects;
create policy "Public can read lesson PDFs" on storage.objects for select to anon, authenticated using (bucket_id='lesson-pdfs');
drop policy if exists "Admins can upload lesson PDFs" on storage.objects;
create policy "Admins can upload lesson PDFs" on storage.objects for insert to authenticated with check (bucket_id='lesson-pdfs' and public.is_site_admin());
drop policy if exists "Admins can update lesson PDFs" on storage.objects;
create policy "Admins can update lesson PDFs" on storage.objects for update to authenticated using (bucket_id='lesson-pdfs' and public.is_site_admin()) with check (bucket_id='lesson-pdfs' and public.is_site_admin());
drop policy if exists "Admins can delete lesson PDFs" on storage.objects;
create policy "Admins can delete lesson PDFs" on storage.objects for delete to authenticated using (bucket_id='lesson-pdfs' and public.is_site_admin());
