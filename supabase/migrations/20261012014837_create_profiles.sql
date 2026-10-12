-- Profiles: one row per auth user, as used by lib/pages/account_page.dart
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  updated_at timestamptz,
  username text,
  website text,
  avatar_url text
);

-- Unique usernames, ignoring blanks (the app saves '' when the field is empty)
create unique index profiles_username_key on public.profiles (username)
  where username is not null and username <> '';

alter table public.profiles enable row level security;

create policy "Profiles are viewable by everyone"
  on public.profiles for select
  using (true);

create policy "Users can insert their own profile"
  on public.profiles for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Create a profile automatically when a user signs up
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Avatars bucket: public URLs are read via getPublicUrl in lib/components/avatar.dart
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true);

create policy "Avatar images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Authenticated users can upload an avatar"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'avatars');
