-- Avatars are stored as <user id>/<file>; users may only upload into their
-- own folder. Updates and deletes stay denied (no policies), so no one can
-- overwrite or remove another user's files.
drop policy "Authenticated users can upload an avatar" on storage.objects;

create policy "Users can upload avatars to their own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
