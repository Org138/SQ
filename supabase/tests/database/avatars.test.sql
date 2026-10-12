-- Avatars bucket limits and storage policies (see the create_profiles,
-- scope_avatar_uploads_per_user, restrict_avatar_file_types and
-- drop_avatar_listing_policy migrations).
-- Runs with `supabase test db`.
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

-- Storage itself enforces these when a file is uploaded
select is(
  (select file_size_limit from storage.buckets where id = 'avatars'),
  1048576::bigint,
  'avatars are limited to 1 MiB'
);

select is(
  (select allowed_mime_types from storage.buckets where id = 'avatars'),
  array['image/jpeg', 'image/png', 'image/webp'],
  'avatars must be JPEG, PNG or WebP'
);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');

-- Act as Alice
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ insert into storage.objects (bucket_id, name)
     values ('avatars', '11111111-1111-1111-1111-111111111111/1.png') $$,
  'users can upload an image to their own folder'
);

select lives_ok(
  $$ insert into storage.objects (bucket_id, name)
     values ('avatars', '11111111-1111-1111-1111-111111111111/2.JPG') $$,
  'the extension check ignores case'
);

select throws_ok(
  $$ insert into storage.objects (bucket_id, name)
     values ('avatars', '11111111-1111-1111-1111-111111111111/3.svg') $$,
  '42501', null,
  'SVG files are rejected'
);

select throws_ok(
  $$ insert into storage.objects (bucket_id, name)
     values ('avatars', '11111111-1111-1111-1111-111111111111/4.html') $$,
  '42501', null,
  'HTML files are rejected'
);

select throws_ok(
  $$ insert into storage.objects (bucket_id, name)
     values ('avatars', '22222222-2222-2222-2222-222222222222/5.png') $$,
  '42501', null,
  'users can''t upload into someone else''s folder'
);

-- Public URLs don't go through policies, so nobody needs to list the bucket
select is_empty(
  $$ select name from storage.objects where bucket_id = 'avatars' $$,
  'signed-in users can''t list avatar files, not even their own'
);

set local role anon;
select set_config('request.jwt.claims', '{"role": "anon"}', true);

select is_empty(
  $$ select name from storage.objects where bucket_id = 'avatars' $$,
  'anonymous users can''t list avatar files'
);

select * from finish();
rollback;
