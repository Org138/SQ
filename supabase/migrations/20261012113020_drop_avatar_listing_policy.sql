-- The avatars bucket is public, so its files are served at
-- /storage/v1/object/public/avatars/... without checking any policy. This
-- select policy only added the ability to list every file in the bucket
-- (and so every user id with an avatar). The app never lists files, and
-- uploads don't upsert, so nothing needs it.
drop policy "Avatar images are publicly accessible" on storage.objects;
