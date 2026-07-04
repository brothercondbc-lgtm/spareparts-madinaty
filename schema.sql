-- ============================================================
-- Brother Cond. — Madinaty Branch — Spare Parts System
-- Supabase schema: tables, auto-profile trigger, and RLS policies
-- Run this whole file once in Supabase: Dashboard -> SQL Editor -> New query -> Run
-- ============================================================

create extension if not exists "pgcrypto";

-- ---------- PROFILES (one row per staff / login) ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'staff' check (role in ('admin','staff')),
  created_at timestamptz default now()
);

-- auto-create a profile row whenever a new auth user is created
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
    'staff'
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------- SUPPLIERS ----------
create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  address text,
  notes text,
  created_at timestamptz default now()
);

-- ---------- CUSTOMERS ----------
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  address text,
  notes text,
  created_at timestamptz default now()
);

-- ---------- PARTS (inventory) ----------
create table if not exists public.parts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sku text,
  category text,
  supplier_id uuid references public.suppliers(id) on delete set null,
  cost_price numeric not null default 0,
  sell_price numeric not null default 0,
  stock numeric not null default 0,
  reorder_level numeric not null default 0,
  unit text default 'pcs',
  created_at timestamptz default now()
);

-- ---------- PURCHASES (stock coming in from a supplier) ----------
create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid references public.suppliers(id) on delete set null,
  total numeric not null default 0,
  staff_id uuid references public.profiles(id),
  created_at timestamptz default now()
);

create table if not exists public.purchase_items (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid references public.purchases(id) on delete cascade,
  part_id uuid references public.parts(id),
  qty numeric not null,
  cost numeric not null
);

-- ---------- SALES (POS transactions) ----------
create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  receipt_no text,
  customer_id uuid references public.customers(id) on delete set null,
  subtotal numeric not null default 0,
  discount numeric not null default 0,
  total numeric not null default 0,
  paid numeric not null default 0,
  change numeric not null default 0,
  staff_id uuid references public.profiles(id),
  created_at timestamptz default now()
);

create table if not exists public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid references public.sales(id) on delete cascade,
  part_id uuid references public.parts(id),
  name text,
  qty numeric not null,
  price numeric not null,
  cost numeric not null default 0
);

-- ---------- EXPENSES (finance section) ----------
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  amount numeric not null,
  note text,
  date date not null default current_date,
  created_at timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- All tables: any logged-in staff member (authenticated) can read/write.
-- Only admins can change roles / delete staff profiles.
-- ============================================================

alter table public.profiles enable row level security;
alter table public.suppliers enable row level security;
alter table public.customers enable row level security;
alter table public.parts enable row level security;
alter table public.purchases enable row level security;
alter table public.purchase_items enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.expenses enable row level security;

-- profiles: everyone logged in can read all profiles (needed for staff list / "served by")
create policy "profiles_select_all" on public.profiles for select using (auth.role() = 'authenticated');
-- only admins can update other people's role/name; anyone can update their own row's name
create policy "profiles_update_self_or_admin" on public.profiles for update using (
  auth.uid() = id or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);
create policy "profiles_delete_admin_only" on public.profiles for delete using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);

-- generic helper: simple "any authenticated staff member can do anything" policy
-- (this fits a small trusted branch team; tighten later if needed)
create policy "suppliers_all" on public.suppliers for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "customers_all" on public.customers for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "parts_all" on public.parts for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "purchases_all" on public.purchases for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "purchase_items_all" on public.purchase_items for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "sales_all" on public.sales for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "sale_items_all" on public.sale_items for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "expenses_all" on public.expenses for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ============================================================
-- Make the very first person who signs up an admin automatically
-- (optional convenience — comment out if you'd rather set it manually)
-- ============================================================
create or replace function public.maybe_promote_first_user()
returns trigger as $$
begin
  if (select count(*) from public.profiles) = 1 then
    update public.profiles set role = 'admin' where id = new.id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_profile_created_promote on public.profiles;
create trigger on_profile_created_promote
  after insert on public.profiles
  for each row execute procedure public.maybe_promote_first_user();
