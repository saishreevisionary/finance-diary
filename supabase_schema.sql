-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Companies Table
create table if not exists public.companies (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  created_at timestamp with time zone default now()
);

alter table public.companies enable row level security;
create policy "Enable all access for companies" on public.companies for all using (true) with check (true);

-- 1. Parties Table
create table if not exists public.parties (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid references public.companies(id) on delete set null,
  name text not null,
  mobile_no text,
  principal numeric not null,
  interest_percent numeric not null,
  bima numeric not null default 0,
  is_debt_u boolean not null default false,
  payment_type text not null default 'due' check (payment_type in ('due', 'interest')),
  number_of_dues integer, -- Nullable if interest-only
  duration integer, -- Keep for backwards compatibility or general duration
  collection_type text not null check (collection_type in ('daily', 'weekly', 'monthly')),
  start_date timestamp with time zone not null,
  created_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.parties enable row level security;
create policy "Enable all access for now" on public.parties for all using (true) with check (true);

-- Migration SQLs (run if table already exists):
-- ALTER TABLE public.parties ADD COLUMN IF NOT EXISTS company_id uuid REFERENCES public.companies(id);
-- ALTER TABLE public.parties ADD COLUMN IF NOT EXISTS mobile_no text;
-- ALTER TABLE public.parties ADD COLUMN IF NOT EXISTS bima numeric DEFAULT 0;
-- ALTER TABLE public.parties ADD COLUMN IF NOT EXISTS is_debt_u boolean DEFAULT false;

-- 2. Payments Table
create table if not exists public.payments (
  id uuid primary key default uuid_generate_v4(),
  party_id uuid references public.parties(id) on delete cascade not null,
  amount_paid numeric not null,
  date timestamp with time zone not null,
  created_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.payments enable row level security;
create policy "Enable all access for now" on public.payments for all using (true) with check (true);

-- 3. Investments Table
create table if not exists public.investments (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid references public.companies(id) on delete set null,
  investor_name text not null,
  mobile_no text,
  amount_invested numeric not null,
  interest_rate numeric not null,
  return_type text not null default 'monthly' check (return_type in ('monthly', 'lump_sum')),
  start_date timestamp with time zone not null,
  maturity_date timestamp with time zone,
  amount_returned numeric not null default 0,
  status text not null default 'active' check (status in ('active', 'closed', 'overdue')),
  notes text,
  created_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.investments enable row level security;
create policy "Enable all access for investments" on public.investments for all using (true) with check (true);


