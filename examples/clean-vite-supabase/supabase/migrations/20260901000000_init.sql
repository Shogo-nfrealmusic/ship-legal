create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  is_13_plus boolean not null default false
);
alter table public.profiles enable row level security;
create policy "own profile" on public.profiles for select using (auth.uid() = id);

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz default now()
);
alter table public.posts enable row level security;
create policy "posts are public" on public.posts for select using (true);
create policy "insert own posts" on public.posts for insert with check (auth.uid() = user_id);
create policy "delete own posts" on public.posts for delete using (auth.uid() = user_id);

create table public.reports (
  id bigint generated always as identity primary key,
  post_id uuid references public.posts(id) on delete cascade,
  reporter_id uuid default auth.uid(),
  reason text
);
alter table public.reports enable row level security;
create policy "insert reports" on public.reports for insert with check (auth.uid() = reporter_id);

create table public.blocks (
  blocker_id uuid default auth.uid() references auth.users(id) on delete cascade,
  blocked_id uuid references auth.users(id) on delete cascade,
  primary key (blocker_id, blocked_id)
);
alter table public.blocks enable row level security;
create policy "own blocks" on public.blocks for all using (auth.uid() = blocker_id) with check (auth.uid() = blocker_id);
