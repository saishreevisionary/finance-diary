-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Parties Table
create table public.parties (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  principal numeric not null,
  interest_percent numeric not null,
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


-- 2. Payments Table
create table public.payments (
  id uuid primary key default uuid_generate_v4(),
  party_id uuid references public.parties(id) on delete cascade not null,
  amount_paid numeric not null,
  date timestamp with time zone not null,
  created_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.payments enable row level security;
create policy "Enable all access for now" on public.payments for all using (true) with check (true);
