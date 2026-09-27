create table public.profiles (
  id uuid primary key references auth.users(id),
  username text unique,
  email text,
  created_at timestamptz default now()
);

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  username text,
  body text not null,
  photo_url text,
  created_at timestamptz default now()
);

insert into storage.buckets (id, name, public) values ('photos', 'photos', true);
